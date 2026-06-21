import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';
class DataPeriodBody extends StatefulWidget {
  const DataPeriodBody({super.key});

  @override
  State<DataPeriodBody> createState() => _DataPeriodBodyState();
}

class _DataPeriodBodyState extends State<DataPeriodBody> {
  String selectedPeriod = "Daily";
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.BgColorWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month,
              color: AppColors.blue),
          SizedBox(width: 8),
          Text(
            "Data Period",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Spacer(),

          /// Select Period
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "Daily",
                child: Text("Daily"),
              ),
              PopupMenuItem(
                value: "Weekly",
                child: Text("Weekly"),
              ),
              PopupMenuItem(
                value: "Monthly",
                child: Text("Monthly"),
              ),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xffF1F3F6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedPeriod,
                    style: TextStyle(
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
