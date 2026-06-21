
from __future__ import annotations

import logging
import math
import subprocess
import threading
import time
from collections import deque
from dataclasses import dataclass, field
from typing import Optional

import cv2
import numpy as np
import requests
import serial
import pynmea2

import lgpio
import smbus2
import board
import busio
import adafruit_vl53l1x

from supabase import create_client
from ultralytics import YOLO
from picamera2 import Picamera2

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("unified_assistive")

i2c_lock = threading.Lock()


@dataclass(frozen=True)
class Config:
    """All tuneable parameters in one place."""

    capture_resolution: tuple[int, int] = (1280, 960)
    display_resolution: tuple[int, int] = (1280, 960)
    yolo_model: str = "yolo11s.pt"
    confidence_threshold: float = 0.40
    frame_skip: int = 3

    announcement_cooldown: float = 5.0

    speech_rate: str = "145"
    speech_volume: str = "180"
    speech_pitch: str = "50"

    priority_labels: frozenset[str] = field(default_factory=lambda: frozenset({
        "person", "car", "truck", "bus", "motorcycle", "bicycle",
        "traffic light", "stop sign", "fire hydrant", "dog", "cat",
        "chair", "dining table", "bottle",
    }))


CFG = Config()
TRIG1  = 23
ECHO1  = 24
TRIG2  = 17
ECHO2  = 27
BUZZER = 18
ULTRASONIC_THRESHOLD_CM = 50

MPU6050_ADDR    = 0x68
PWR_MGMT_1      = 0x6B
ACCEL_XOUT_H    = 0x3B

FALL_THRESHOLD  = 0.85
CONFIRM_TIME    = 1.0
STABLE_TIME     = 1.0
SUPABASE_URL   = "https://dendsqemydqkhhwstzpa.supabase.co"
SUPABASE_KEY   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbmRzcWVteWRxa2hod3N0enBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3Mjk0MzEsImV4cCI6MjA5MzMwNTQzMX0.5l8B5xw7X1WyHUTymf-GHlF2qu58Uv4apHnPSTbAHsM"
SUPABASE_TABLE = "mpu_fall_detected"
SUPABASE_HEADERS = {
    "apikey":        SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type":  "application/json",
    "Prefer":        "return=minimal",
}

GPS_SERIAL_PORT = "/dev/serial0"
GPS_BAUD_RATE   = 9600
GPS_LOOP_DELAY  = 3        
TOF_DISTANCE_MODE = 2
TOF_TIMING_BUDGET = 50

TOF_FILTER_SIZE    = 5
TOF_CONFIRM_COUNT  = 2
TOF_HOLE_THRESHOLD = 8
TOF_CURB_THRESHOLD = 6
TOF_ROLLING_SIZE   = 20
TOF_ALERT_COOLDOWN = 1.5
TOF_LOOP_DELAY     = 0.05
TOF_MAX_STREAK     = 40
TOF_CALIBRATION_S  = 2


@dataclass
class Detection:
    """Single object detection result."""

    label: str
    confidence: float
    distance_label: str
    distance_color: tuple[int, int, int]
    x1: int
    y1: int
    x2: int
    y2: int

    @property
    def is_priority(self) -> bool:
        return self.label in CFG.priority_labels


def setup_pulseaudio() -> bool:
    try:
        subprocess.run(["pulseaudio", "--kill"], capture_output=True)
        time.sleep(1)
        subprocess.run(["pulseaudio", "--start"], capture_output=True)
        time.sleep(2)
        for module in ("module-bluetooth-discover", "module-bluetooth-policy",
                       "module-switch-on-connect"):
            subprocess.run(["pactl", "load-module", module], capture_output=True)
        time.sleep(1)
        log.info("PulseAudio ready.")
        return True
    except Exception:
        log.exception("PulseAudio setup failed.")
        return False


def get_bluetooth_sink() -> Optional[str]:
    try:
        result = subprocess.run(["pactl", "list", "short", "sinks"],
                                capture_output=True, text=True)
        for line in result.stdout.splitlines():
            if "bluez" in line.lower():
                sink_name = line.split()[1]
                log.info("Bluetooth sink found: %s", sink_name)
                return sink_name
    except Exception:
        log.exception("Error finding Bluetooth sink.")
    return None


def set_default_audio_sink(sink_name: str) -> bool:
    try:
        subprocess.run(["pactl", "set-default-sink", sink_name], check=True)
        log.info("Default audio sink set to: %s", sink_name)
        return True
    except Exception:
        log.exception("Failed to set audio sink: %s", sink_name)
        return False


def set_bluetooth_volume(sink_name: str, volume: int = 100) -> None:
    try:
        subprocess.run(["pactl", "set-sink-volume", sink_name, f"{volume}%"], check=True)
        log.info("Volume set to %d%%", volume)
    except Exception:
        log.exception("Failed to set volume.")


def get_bt_mac_from_sink(sink_name: str) -> Optional[str]:
    try:
        parts = sink_name.split(".")
        if len(parts) >= 2:
            return parts[1].replace("_", ":")
    except Exception:
        pass
    return None


def force_a2dp_profile(mac_address: str) -> bool:
    try:
        card_name = f"bluez_card.{mac_address.replace(':', '_')}"
        result = subprocess.run(
            ["pactl", "set-card-profile", card_name, "a2dp_sink"],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            log.info("[BT] A2DP profile set for %s", card_name)
            return True
        else:
            log.warning("[BT] A2DP switch failed: %s", result.stderr.strip())
            return False
    except Exception:
        log.exception("[BT] force_a2dp_profile error.")
        return False

supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY)


def insert_to_supabase(
    magnitude: float,
    status: str,
    fall_detected: bool,
    buzzer_state: str,
    confirm_time: Optional[float] = None,
    stable_time: Optional[float] = None,
) -> None:
    payload = {
        "magnitude":     round(magnitude, 4),
        "status":        status,
        "fall_detected": fall_detected,
        "buzzer_state":  buzzer_state,
        "confirm_time":  confirm_time,
        "stable_time":   stable_time,
    }
    while True:
        try:
            r = requests.post(
                f"{SUPABASE_URL}/rest/v1/{SUPABASE_TABLE}",
                headers=SUPABASE_HEADERS,
                json=payload,
                timeout=5,
            )
            if r.status_code in (200, 201):
                log.info("[Supabase] Row inserted — status=%s fall=%s", status, fall_detected)
                break
            else:
                log.warning("[Supabase] Error %d: %s — retrying in 2 s…", r.status_code, r.text)
                time.sleep(2)
        except requests.exceptions.Timeout:
            log.warning("[Supabase] Timeout — retrying in 2 s…")
            time.sleep(2)
        except requests.exceptions.ConnectionError:
            log.warning("[Supabase] No internet — retrying in 2 s…")
            time.sleep(2)
        except Exception:
            log.exception("[Supabase] Unexpected error — retrying in 2 s…")
            time.sleep(2)

class GPSWeatherThread:
    """
    Reads GPS coordinates from a serial NMEA module and fetches
    current weather from Open-Meteo, then inserts both into the
    `gps_locations` Supabase table every GPS_LOOP_DELAY seconds.
    Runs entirely on a background daemon thread — never blocks main loop.
    """

    def __init__(self) -> None:
        try:
            self._ser = serial.Serial(GPS_SERIAL_PORT, GPS_BAUD_RATE, timeout=1)
            log.info("[GPS] Serial port %s opened.", GPS_SERIAL_PORT)
        except Exception:
            log.exception("[GPS] Failed to open serial port — GPS thread disabled.")
            self._ser = None

        self.running = True
        self._thread = threading.Thread(target=self._loop, daemon=True, name="GPSWeather")
        self._thread.start()
        log.info("GPS+Weather thread started.")

    @staticmethod
    def _get_weather(lat: float, lng: float) -> dict:
        try:
            url = "https://api.open-meteo.com/v1/forecast"
            params = {
                "latitude":        lat,
                "longitude":       lng,
                "current":         "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code",
                "daily":           "temperature_2m_max,temperature_2m_min",
                "wind_speed_unit": "kmh",
                "timezone":        "auto",
            }
            res  = requests.get(url, params=params, timeout=5)
            data = res.json()
            current = data.get("current", {})
            daily   = data.get("daily", {})
            return {
                "temperature":  math.ceil(current.get("temperature_2m")),
                "humidity":     current.get("relative_humidity_2m"),
                "wind_speed":   current.get("wind_speed_10m"),
                "weather_code": current.get("weather_code"),
                "temp_max":     math.ceil(daily.get("temperature_2m_max", [None])[0]),
                "temp_min":     math.ceil(daily.get("temperature_2m_min", [None])[0]),
            }
        except Exception as e:
            log.warning("[GPS] Weather fetch error: %s", e)
            return {}

    def _loop(self) -> None:
        if self._ser is None:
            return

        while self.running:
            try:
                line = self._ser.readline().decode("ascii", errors="replace")
                if line.startswith("$GPRMC") or line.startswith("$GNRMC"):
                    msg = pynmea2.parse(line)
                    if msg.status == "A":
                        lat     = msg.latitude
                        lng     = msg.longitude
                        weather = self._get_weather(lat, lng)
                        record  = {"lat": lat, "lng": lng, **weather}
                        supabase_client.table("gps_locations").insert(record).execute()
                        log.info(
                            "[GPS] Saved: %.6f, %.6f | Temp:%s°C Max:%s Min:%s "
                            "Humidity:%s%% Wind:%s km/h",
                            lat, lng,
                            weather.get("temperature"), weather.get("temp_max"),
                            weather.get("temp_min"), weather.get("humidity"),
                            weather.get("wind_speed"),
                        )
            except Exception as e:
                log.warning("[GPS] Loop error: %s", e)

            time.sleep(GPS_LOOP_DELAY)

    def stop(self) -> None:
        self.running = False
        self._thread.join()
        if self._ser:
            self._ser.close()
        log.info("[GPS] Thread stopped.")


class VoiceEngine:
    _MAX_QUEUE = 2

    def __init__(self, bt_sink: Optional[str] = None) -> None:
        self._bt_sink    = bt_sink
        self._queue: deque[str] = deque(maxlen=self._MAX_QUEUE)
        self._lock       = threading.Lock()
        self._running    = True
        self.is_speaking = False

        self._prewarm()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="VoiceEngine")
        self._thread.start()
        log.info("Voice engine started.")

    def say(self, text: str, *, priority: bool = False) -> None:
        with self._lock:
            if priority:
                self._queue.clear()
            self._queue.append(text)

    def stop(self) -> None:
        self._running = False
        self._thread.join()

    def _prewarm(self) -> None:
        try:
            subprocess.run(
                ["espeak", "-v", "en", "-s", CFG.speech_rate,
                 "-a", "0", "--stdout", "ready"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass

    def _speak(self, text: str) -> None:
        self.is_speaking = True
        espeak_cmd = [
            "espeak", "-v", "en-us",
            "-s", CFG.speech_rate,
            "-a", CFG.speech_volume,
            "-p", CFG.speech_pitch,
            "--stdout", text,
        ]
        try:
            if self._bt_sink:
                esp = subprocess.Popen(espeak_cmd,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.DEVNULL)
                play = subprocess.Popen(["paplay", "--device", self._bt_sink],
                                        stdin=esp.stdout,
                                        stderr=subprocess.DEVNULL)
                esp.stdout.close()
                play.wait()
            else:
                subprocess.run(
                    ["espeak", "-v", "en-us",
                     "-s", CFG.speech_rate,
                     "-a", CFG.speech_volume,
                     "-p", CFG.speech_pitch,
                     text],
                    stderr=subprocess.DEVNULL,
                )
        except Exception:
            log.exception("Speech synthesis failed for: '%s'", text)
        finally:
            self.is_speaking = False

    def _loop(self) -> None:
        while self._running:
            text: Optional[str] = None
            with self._lock:
                if self._queue:
                    text = self._queue.popleft()
            if text:
                self._speak(text)
            else:
                time.sleep(0.02)


class ThreadedCamera:
    _FRAME_DURATION_US = 25_000

    def __init__(self, resolution: tuple[int, int]) -> None:
        self._cam = Picamera2()
        cfg = self._cam.create_preview_configuration(
            main={"size": resolution, "format": "RGB888"},
            controls={
                "FrameDurationLimits": (
                    self._FRAME_DURATION_US,
                    self._FRAME_DURATION_US,
                ),
                "ExposureTime": 30000,
                "AnalogueGain": 6.0,
                "NoiseReductionMode": 2,
                "Sharpness": 3.0,
            },
        )
        self._cam.configure(cfg)
        self._cam.start()
        time.sleep(2)

        self._frame: Optional[np.ndarray] = None
        self._lock    = threading.Lock()
        self._running = True
        self._thread  = threading.Thread(target=self._capture_loop, daemon=True, name="Camera")
        self._thread.start()
        log.info("Camera started at %s.", resolution)

    def read(self) -> Optional[np.ndarray]:
        with self._lock:
            return self._frame.copy() if self._frame is not None else None

    def stop(self) -> None:
        self._running = False
        self._thread.join()
        self._cam.stop()

    def _capture_loop(self) -> None:
        while self._running:
            frame = self._cam.capture_array()
            with self._lock:
                self._frame = frame


class YOLOInferenceThread:
    def __init__(self, model: YOLO) -> None:
        self._model    = model
        self._input:   Optional[np.ndarray] = None
        self._results: list[Detection] = []
        self._lock      = threading.Lock()
        self._running   = True
        self._new_frame = threading.Event()
        self._thread    = threading.Thread(
            target=self._inference_loop, daemon=True, name="YOLOInference"
        )
        self._thread.start()
        log.info("YOLO inference thread started.")

    def submit(self, frame: np.ndarray) -> None:
        with self._lock:
            self._input = frame.copy()
        self._new_frame.set()

    def get_results(self) -> list[Detection]:
        with self._lock:
            return list(self._results)

    def stop(self) -> None:
        self._running = False
        self._new_frame.set()
        self._thread.join()

    def _inference_loop(self) -> None:
        while self._running:
            self._new_frame.wait(timeout=0.1)
            self._new_frame.clear()

            with self._lock:
                frame = self._input

            if frame is None:
                continue

            raw = self._model(
                frame, verbose=False,
                imgsz=416,
                conf=CFG.confidence_threshold,
            )
            detections = self._parse(raw[0].boxes, frame.shape[0])

            with self._lock:
                self._results = detections

    def _parse(self, boxes, frame_height: int) -> list[Detection]:
        results: list[Detection] = []
        for box in boxes:
            conf = float(box.conf[0])
            if conf < CFG.confidence_threshold:
                continue
            label = self._model.names[int(box.cls[0])]
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            dist_label, dist_color = estimate_distance(y2 - y1, frame_height)
            results.append(Detection(
                label=label,
                confidence=conf,
                distance_label=dist_label,
                distance_color=dist_color,
                x1=x1, y1=y1, x2=x2, y2=y2,
            ))
        return results


class FPSCounter:
    def __init__(self, window: int = 60) -> None:
        self._timestamps: deque[float] = deque(maxlen=window)

    def tick(self) -> None:
        self._timestamps.append(time.perf_counter())

    @property
    def fps(self) -> float:
        if len(self._timestamps) < 2:
            return 0.0
        return (len(self._timestamps) - 1) / (
            self._timestamps[-1] - self._timestamps[0]
        )


class AnnouncementTracker:
    def __init__(self) -> None:
        self._last: dict[str, float] = {}

    def should_announce(self, label: str) -> bool:
        now = time.time()
        if now - self._last.get(label, 0.0) > CFG.announcement_cooldown:
            self._last[label] = now
            return True
        return False


class UltrasonicBuzzerThread:
    def __init__(self, gpio_handle, fall_buzzer_active: threading.Event):
        self.h                  = gpio_handle
        self.fall_buzzer_active = fall_buzzer_active
        self.dist1              = -1
        self.dist2              = -1
        self.lock               = threading.Lock()
        self.running            = True
        self.buzzer_state       = None
        self.thread             = threading.Thread(target=self._loop, daemon=True,
                                                   name="Ultrasonic")
        self.thread.start()
        log.info("Ultrasonic thread started.")

    def _get_distance(self, trig, echo):
        lgpio.gpio_write(self.h, trig, 0)
        time.sleep(0.05)
        lgpio.gpio_write(self.h, trig, 1)
        time.sleep(0.00001)
        lgpio.gpio_write(self.h, trig, 0)

        timeout     = time.perf_counter()
        pulse_start = timeout
        pulse_end   = timeout

        while lgpio.gpio_read(self.h, echo) == 0:
            pulse_start = time.perf_counter()
            if pulse_start - timeout > 0.03:
                return -1

        while lgpio.gpio_read(self.h, echo) == 1:
            pulse_end = time.perf_counter()
            if pulse_end - timeout > 0.03:
                return -1

        return round((pulse_end - pulse_start) * 17150, 2)

    def _loop(self):
        while self.running:
            d1 = self._get_distance(TRIG1, ECHO1)
            time.sleep(0.15)
            d2 = self._get_distance(TRIG2, ECHO2)
            time.sleep(0.15)

            with self.lock:
                self.dist1 = d1
                self.dist2 = d2

            if self.fall_buzzer_active.is_set():
                time.sleep(0.3)
                continue

            obstacle = (d1 != -1 and d1 < ULTRASONIC_THRESHOLD_CM) or \
                       (d2 != -1 and d2 < ULTRASONIC_THRESHOLD_CM)

            if obstacle:
                lgpio.gpio_write(self.h, BUZZER, 1)
                if self.buzzer_state != "ON":
                    log.info("[ULTRASONIC] BUZZER ON — S1:%.1fcm  S2:%.1fcm", d1, d2)
                    self.buzzer_state = "ON"
            else:
                lgpio.gpio_write(self.h, BUZZER, 0)
                if self.buzzer_state != "OFF":
                    log.info("[ULTRASONIC] BUZZER OFF — S1:%.1fcm  S2:%.1fcm", d1, d2)
                    self.buzzer_state = "OFF"

            time.sleep(0.3)

    def get_distances(self):
        with self.lock:
            return self.dist1, self.dist2

    def stop(self):
        self.running = False
        self.thread.join()
        lgpio.gpio_write(self.h, BUZZER, 0)


class TOFThread:
    def __init__(self, voice_engine: VoiceEngine) -> None:
        self.voice        = voice_engine
        self.distance_cm: Optional[float] = None
        self.lock         = threading.Lock()
        self.running      = True

        i2c = busio.I2C(board.SCL, board.SDA)
        self.sensor = adafruit_vl53l1x.VL53L1X(i2c)
        self.sensor.distance_mode = TOF_DISTANCE_MODE
        self.sensor.timing_budget = TOF_TIMING_BUDGET
        self.sensor.start_ranging()

        log.info("[TOF] Calibrating... hold the cane normally for %ds", TOF_CALIBRATION_S)
        self.voice.say("Calibrating cane sensor. Hold cane normally.")

        readings  = []
        cal_start = time.time()
        while time.time() - cal_start < TOF_CALIBRATION_S:
            with i2c_lock:
                ready = self.sensor.data_ready
            if ready:
                with i2c_lock:
                    d = self.sensor.distance
                    self.sensor.clear_interrupt()
                if d:
                    readings.append(d)
            time.sleep(TOF_LOOP_DELAY)

        fallback = 50
        if readings:
            baseline = sorted(readings)[len(readings) // 2]
        else:
            baseline = fallback
            log.warning("[TOF] Calibration failed — using default %dcm", fallback)

        log.info(
            "[TOF] Calibration done! Baseline=%.1fcm | Hole>%.1fcm | Curb<%.1fcm",
            baseline,
            baseline + TOF_HOLE_THRESHOLD,
            baseline - TOF_CURB_THRESHOLD,
        )
        self.voice.say("Calibration done. Detection running.")

        self._baseline  = baseline
        self._roll_buf  = deque([baseline] * TOF_ROLLING_SIZE, TOF_ROLLING_SIZE)
        self._raw_buf   = deque([baseline] * TOF_FILTER_SIZE,  TOF_FILTER_SIZE)
        self._last_alert = {"hole": 0.0, "curb": 0.0}
        self._hole_streak = 0
        self._curb_streak = 0

        self.thread = threading.Thread(target=self._loop, daemon=True, name="TOF")
        self.thread.start()
        log.info("TOF thread started.")

    def _loop(self) -> None:
        while self.running:
            with i2c_lock:
                ready = self.sensor.data_ready

            if not ready:
                time.sleep(TOF_LOOP_DELAY)
                continue

            with i2c_lock:
                raw = self.sensor.distance
                self.sensor.clear_interrupt()

            if raw is None:
                time.sleep(TOF_LOOP_DELAY)
                continue

            self._raw_buf.append(raw)
            dist = sorted(self._raw_buf)[TOF_FILTER_SIZE // 2]

            with self.lock:
                self.distance_cm = dist

            if abs(dist - self._baseline) < TOF_CURB_THRESHOLD:
                self._roll_buf.append(dist)
                self._baseline = sum(self._roll_buf) / len(self._roll_buf)

            now = time.time()

            if dist > self._baseline + TOF_HOLE_THRESHOLD:
                self._hole_streak += 1
                self._curb_streak  = 0

                if (self._hole_streak >= TOF_CONFIRM_COUNT and
                        now - self._last_alert["hole"] > TOF_ALERT_COOLDOWN):
                    self.voice.say("Warning! Hole ahead!", priority=True)
                    log.info("[TOF] HOLE detected! dist=%.1fcm  baseline=%.1fcm",
                             dist, self._baseline)
                    self._last_alert["hole"] = now

                if self._hole_streak > TOF_MAX_STREAK:
                    log.info("[TOF] Adapting to new lower ground: %.1fcm", dist)
                    self._baseline  = dist
                    self._roll_buf  = deque([dist] * TOF_ROLLING_SIZE, TOF_ROLLING_SIZE)
                    self._hole_streak = 0

            elif dist < self._baseline - TOF_CURB_THRESHOLD:
                self._curb_streak += 1
                self._hole_streak  = 0

                if (self._curb_streak >= TOF_CONFIRM_COUNT and
                        now - self._last_alert["curb"] > TOF_ALERT_COOLDOWN):
                    self.voice.say("Warning! Curb or step ahead!", priority=True)
                    log.info("[TOF] CURB detected! dist=%.1fcm  baseline=%.1fcm",
                             dist, self._baseline)
                    self._last_alert["curb"] = now

                if self._curb_streak > TOF_MAX_STREAK:
                    log.info("[TOF] Adapting to new higher ground: %.1fcm", dist)
                    self._baseline  = dist
                    self._roll_buf  = deque([dist] * TOF_ROLLING_SIZE, TOF_ROLLING_SIZE)
                    self._curb_streak = 0

            else:
                self._hole_streak = 0
                self._curb_streak = 0
                log.debug("[TOF] Clear. dist=%.1fcm  baseline=%.1fcm",
                          dist, self._baseline)

            time.sleep(TOF_LOOP_DELAY)

    def get_distance(self) -> Optional[float]:
        with self.lock:
            return self.distance_cm

    def stop(self) -> None:
        self.running = False
        self.thread.join()
        self.sensor.stop_ranging()


class MPU6050FallThread:
    def __init__(
        self,
        gpio_handle,
        voice_engine: VoiceEngine,
        fall_buzzer_active: threading.Event,
    ) -> None:
        self._h                  = gpio_handle
        self._voice              = voice_engine
        self._fall_buzzer_active = fall_buzzer_active
        self.running             = True

        with i2c_lock:
            self._bus = smbus2.SMBus(1)
            self._bus.write_byte_data(MPU6050_ADDR, PWR_MGMT_1, 0)

        log.info("[MPU] MPU6050 initialised at 0x%02X", MPU6050_ADDR)

        self._thread = threading.Thread(target=self._loop, daemon=True, name="MPU6050Fall")
        self._thread.start()
        log.info("MPU6050 fall-detection thread started.")

    def _read_raw(self, addr: int) -> int:
        with i2c_lock:
            high  = self._bus.read_byte_data(MPU6050_ADDR, addr)
            low   = self._bus.read_byte_data(MPU6050_ADDR, addr + 1)
        value = (high << 8) | low
        if value > 32767:
            value -= 65536
        return value

    def _get_acceleration(self) -> tuple[float, float, float, float]:
        ax = self._read_raw(ACCEL_XOUT_H)     / 16384.0
        ay = self._read_raw(ACCEL_XOUT_H + 2) / 16384.0
        az = self._read_raw(ACCEL_XOUT_H + 4) / 16384.0
        magnitude = math.sqrt(ax**2 + ay**2 + az**2)
        return ax, ay, az, magnitude

    def _log_to_supabase_async(self, **kwargs) -> None:
        t = threading.Thread(
            target=insert_to_supabase,
            kwargs=kwargs,
            daemon=True,
            name="SupabaseInsert",
        )
        t.start()

    def _set_buzzer(self, on: bool) -> None:
        lgpio.gpio_write(self._h, BUZZER, 1 if on else 0)
        if on:
            self._fall_buzzer_active.set()
        else:
            self._fall_buzzer_active.clear()

    def _loop(self) -> None:
        fall_detected     = False
        fall_start_time   = 0.0
        stable_start_time = 0.0

        while self.running:
            try:
                ax, ay, az, magnitude = self._get_acceleration()
            except Exception:
                log.exception("[MPU] Read error — skipping cycle.")
                time.sleep(0.2)
                continue

            current_time  = time.time()
            fallen_pos    = abs(ay) < FALL_THRESHOLD

            if fallen_pos:
                if not fall_detected:
                    if fall_start_time == 0.0:
                        fall_start_time = current_time
                    elif current_time - fall_start_time >= CONFIRM_TIME:
                        confirm_t         = round(current_time - fall_start_time, 3)
                        fall_detected     = True
                        stable_start_time = 0.0
                        self._set_buzzer(True)
                        self._voice.say("Fall detected!", priority=True)
                        log.warning(
                            "[MPU] FALL confirmed! mag=%.2f  confirm_t=%.2fs",
                            magnitude, confirm_t,
                        )
                        self._log_to_supabase_async(
                            magnitude=magnitude,
                            status="FREE_FALL",
                            fall_detected=True,
                            buzzer_state="ON",
                            confirm_time=confirm_t,
                        )
            else:
                fall_start_time = 0.0

                if fall_detected:
                    if stable_start_time == 0.0:
                        stable_start_time = current_time
                    elif current_time - stable_start_time >= STABLE_TIME:
                        stable_t          = round(current_time - stable_start_time, 3)
                        fall_detected     = False
                        stable_start_time = 0.0
                        self._set_buzzer(False)
                        self._voice.say("Person recovered.", priority=True)
                        log.info(
                            "[MPU] Fall CLEARED. mag=%.2f  stable_t=%.2fs",
                            magnitude, stable_t,
                        )
                        self._log_to_supabase_async(
                            magnitude=magnitude,
                            status="NORMAL",
                            fall_detected=False,
                            buzzer_state="OFF",
                            stable_time=stable_t,
                        )
                else:
                    stable_start_time = 0.0

            log.debug(
                "[MPU] AX=%.2f AY=%.2f AZ=%.2f MAG=%.2f  fallen=%s  detected=%s",
                ax, ay, az, magnitude, fallen_pos, fall_detected,
            )

            time.sleep(0.2)

    def stop(self) -> None:
        self.running = False
        self._thread.join()
        self._set_buzzer(False)
        self._bus.close()


def estimate_distance(
    box_height: int,
    frame_height: int,
) -> tuple[str, tuple[int, int, int]]:
    ratio = box_height / frame_height
    if ratio > 0.70:
        return "very close", (0, 0, 255)
    elif ratio > 0.40:
        return "close",      (0, 100, 255)
    elif ratio > 0.20:
        return "nearby",     (0, 255, 255)
    else:
        return "far away",   (0, 255, 0)


def _scale_detections(
    detections: list[Detection],
    sx: float,
    sy: float,
) -> list[Detection]:
    return [
        Detection(
            label=d.label,
            confidence=d.confidence,
            distance_label=d.distance_label,
            distance_color=d.distance_color,
            x1=int(d.x1 * sx), y1=int(d.y1 * sy),
            x2=int(d.x2 * sx), y2=int(d.y2 * sy),
        )
        for d in detections
    ]


def draw_detections(
    frame: np.ndarray,
    detections: list[Detection],
) -> np.ndarray:
    for d in detections:
        color     = (0, 0, 255) if d.is_priority else d.distance_color
        thickness = 3 if d.is_priority else 2

        cv2.rectangle(frame, (d.x1, d.y1), (d.x2, d.y2), color, thickness)

        label = f"{d.label} {d.confidence:.0%} | {d.distance_label}"
        (lw, lh), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.65, 2)
        cv2.rectangle(frame, (d.x1, d.y1 - lh - 10), (d.x1 + lw, d.y1), color, -1)
        cv2.putText(frame, label, (d.x1, d.y1 - 5),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.65, (255, 255, 255), 2)

        if d.is_priority:
            cv2.putText(frame, "! CAUTION", (d.x1, d.y2 + 22),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 0, 255), 2)
    return frame


def draw_hud(
    frame: np.ndarray,
    fps: float,
    total_objects: int,
    priority_count: int,
    bt_connected: bool,
    speaking: bool,
    dist1: float,
    dist2: float,
    tof_cm: Optional[float],
    fall_active: bool = False,
) -> np.ndarray:
    h, w = frame.shape[:2]

    cv2.rectangle(frame, (0, 0), (w, 130), (15, 15, 15), -1)

    fps_color = (0, 255, 0) if fps >= 20 else (0, 165, 255) if fps >= 10 else (0, 0, 255)
    cv2.putText(frame, f"FPS: {fps:.1f}", (10, 28),
                cv2.FONT_HERSHEY_SIMPLEX, 0.85, fps_color, 2)

    cv2.putText(frame, f"Objects: {total_objects}", (10, 58),
                cv2.FONT_HERSHEY_SIMPLEX, 0.75, (255, 255, 255), 2)
    p_color = (0, 0, 255) if priority_count > 0 else (255, 255, 255)
    cv2.putText(frame, f"Priority: {priority_count}", (10, 88),
                cv2.FONT_HERSHEY_SIMPLEX, 0.75, p_color, 2)

    s1_txt  = f"S1:{dist1:.0f}cm" if dist1 != -1 else "S1:--"
    s2_txt  = f"S2:{dist2:.0f}cm" if dist2 != -1 else "S2:--"
    tof_txt = f"TOF:{tof_cm:.1f}cm" if tof_cm is not None else "TOF:--"
    cv2.putText(frame, f"{s1_txt}  {s2_txt}  {tof_txt}", (10, 118),
                cv2.FONT_HERSHEY_SIMPLEX, 0.60, (200, 200, 0), 2)

    bt_color  = (0, 255, 0) if bt_connected else (0, 0, 255)
    bt_status = "BT: Connected" if bt_connected else "BT: No device"
    cv2.putText(frame, bt_status, (w - 250, 28),
                cv2.FONT_HERSHEY_SIMPLEX, 0.62, bt_color, 2)

    spk_color  = (0, 255, 255) if speaking else (80, 80, 80)
    spk_status = "Speaking..." if speaking else "Silent"
    cv2.putText(frame, spk_status, (w - 200, 58),
                cv2.FONT_HERSHEY_SIMPLEX, 0.62, spk_color, 2)

    cv2.putText(frame, "RED=Priority | COLOUR=Distance",
                (w - 310, 88), cv2.FONT_HERSHEY_SIMPLEX, 0.46, (180, 180, 180), 1)

    if fall_active:
        cv2.rectangle(frame, (0, 130), (w, 175), (0, 0, 180), -1)
        cv2.putText(frame, "⚠ FALL DETECTED — BUZZER ON", (10, 162),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.85, (255, 255, 255), 2)

    cv2.rectangle(frame, (0, h - 32), (w, h), (15, 15, 15), -1)
    cv2.putText(frame, "Q / ESC = Quit", (10, h - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.55, (120, 120, 120), 1)

    return frame


def main() -> None:
    log.info("=" * 60)
    log.info("  Unified Assistive System - Starting Up")
    log.info("=" * 60)

    h = lgpio.gpiochip_open(0)
    lgpio.gpio_claim_output(h, TRIG1)
    lgpio.gpio_claim_input(h,  ECHO1)
    lgpio.gpio_claim_output(h, TRIG2)
    lgpio.gpio_claim_input(h,  ECHO2)
    lgpio.gpio_claim_output(h, BUZZER)
    lgpio.gpio_write(h, BUZZER, 0)
    log.info("GPIO initialised.")

    fall_buzzer_active = threading.Event()

    log.info("Setting up audio...")
    setup_pulseaudio()

    bt_sink      = get_bluetooth_sink()
    bt_connected = False

    if bt_sink:
        mac = get_bt_mac_from_sink(bt_sink)
        if mac:
            log.info("[BT] MAC detected: %s — switching to A2DP...", mac)
            time.sleep(1)
            force_a2dp_profile(mac)
            time.sleep(2)
            bt_sink = get_bluetooth_sink()

        if bt_sink:
            bt_connected = set_default_audio_sink(bt_sink)
            if bt_connected:
                set_bluetooth_volume(bt_sink, 100)
                log.info("AirPods connected (A2DP).")
    else:
        log.warning("No Bluetooth device found - using default audio.")

    voice = VoiceEngine(bt_sink=bt_sink)
    voice.say("Bluetooth connected. System starting." if bt_connected
              else "System starting.")
    time.sleep(2)

    ultrasonic_thread = UltrasonicBuzzerThread(h, fall_buzzer_active)
    tof_thread        = TOFThread(voice)
    fall_thread       = MPU6050FallThread(h, voice, fall_buzzer_active)
    gps_thread        = GPSWeatherThread()                          

    log.info("Loading YOLO model: %s", CFG.yolo_model)
    model = YOLO(CFG.yolo_model)
    log.info("Warming up model...")
    dummy = np.zeros((416, 416, 3), dtype=np.uint8)
    for _ in range(3):
        model(dummy, verbose=False, imgsz=416)
    log.info("Model ready.")

    camera      = ThreadedCamera(CFG.capture_resolution)
    yolo_thread = YOLOInferenceThread(model)

    scale_x = CFG.display_resolution[0] / CFG.capture_resolution[0]
    scale_y = CFG.display_resolution[1] / CFG.capture_resolution[1]

    fps_counter  = FPSCounter()
    tracker      = AnnouncementTracker()
    last_results: list[Detection] = []
    frame_count  = 0

    voice.say("Camera ready. Detection running.")
    log.info("Running — press Q or ESC to quit.")
    log.info("=" * 60)

    try:
        while True:
            frame = camera.read()
            if frame is None:
                continue

            frame_count += 1
            run_inference = (frame_count % CFG.frame_skip == 0)

            if run_inference:
                yolo_thread.submit(frame)

            last_results = yolo_thread.get_results()

            if run_inference:
                sorted_results = sorted(
                    last_results,
                    key=lambda d: (not d.is_priority, -d.confidence),
                )

                for det in sorted_results:
                    if tracker.should_announce(det.label):
                        is_close = det.distance_label in ("very close", "close")

                        if det.is_priority and is_close:
                            voice.say(f"Warning! {det.label}, {det.distance_label}", priority=True)
                            log.info("[PRIORITY] %s — %s (%.0f%%)",
                                     det.label, det.distance_label, det.confidence * 100)
                        elif not det.is_priority and is_close:
                            voice.say(f"{det.label}, {det.distance_label}")
                            log.info("[INFO] %s — %s (%.0f%%)",
                                     det.label, det.distance_label, det.confidence * 100)
                        else:
                            log.debug("[SILENT] %s — %s (%.0f%%)",
                                      det.label, det.distance_label, det.confidence * 100)

            display = cv2.resize(frame, CFG.display_resolution,
                                 interpolation=cv2.INTER_LINEAR)
            scaled  = _scale_detections(last_results, scale_x, scale_y)
            display = draw_detections(display, scaled)

            fps_counter.tick()
            priority_count = sum(1 for d in last_results if d.is_priority)
            d1, d2  = ultrasonic_thread.get_distances()
            tof_cm  = tof_thread.get_distance()

            display = draw_hud(
                display,
                fps=fps_counter.fps,
                total_objects=len(last_results),
                priority_count=priority_count,
                bt_connected=bt_connected,
                speaking=voice.is_speaking,
                dist1=d1,
                dist2=d2,
                tof_cm=tof_cm,
                fall_active=fall_buzzer_active.is_set(),
            )

            cv2.imshow("Unified Assistive System", display)

            key = cv2.waitKey(1)
            if key == 27 or key == ord('q'):
                voice.say("Shutting down. Goodbye.", priority=True)
                time.sleep(2)
                break

    except KeyboardInterrupt:
        log.info("Interrupted by user.")

    finally:
        log.info("Stopping threads...")
        camera.stop()
        yolo_thread.stop()
        ultrasonic_thread.stop()
        fall_thread.stop()
        tof_thread.stop()
        gps_thread.stop()                                           
        voice.stop()
        cv2.destroyAllWindows()
        lgpio.gpiochip_close(h)
        log.info("Done.")


if __name__ == "__main__":
    main()
