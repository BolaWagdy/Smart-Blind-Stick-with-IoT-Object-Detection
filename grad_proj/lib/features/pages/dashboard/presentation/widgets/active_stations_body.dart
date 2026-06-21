import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';
class ActiveStationsBody extends StatelessWidget {
  const ActiveStationsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, color: AppColors.blue, size: 24),
            SizedBox(width: 4),
            Text("Active Stations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ],
        ),
        SizedBox(height: 8),

        // Card 1
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Delhi DWLR", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                      Text("2 mins ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text("45.2m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text("normal", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Card 2
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mumbai DWLR", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                      Text("5 mins ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text("38.7m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text("low", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Card 3
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bangalore DWLR", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                      Text("1 min ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text("52.1m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text("high", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Card 4
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kolkata DWLR", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                      Text("3 mins ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text("41.9m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text("normal", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Card 5
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Chennai DWLR", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                      Text("4 mins ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text("39.8m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text("normal", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Card 6
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hyderabad DWLR", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                      Text("1 min ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text("52.1m", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text("normal", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // تقدر تكمل بنفس الطريقة لباقي المحطات مع أي ألوان عايزها
      ],
    );
  }
}
