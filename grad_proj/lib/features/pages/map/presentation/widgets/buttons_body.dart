import 'package:flutter/material.dart';
import 'package:grad_proj/core/resourses/app_colors.dart';
class ButtonsBody extends StatelessWidget {
  const ButtonsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // minus button
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: AppColors.green,
          ),
          child: Icon(Icons.remove,color: AppColors.BgColorWhite,),
        ),

        const SizedBox(width: 20),

        // plus button
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: AppColors.green,
          ),
          child: Icon(Icons.add,color: AppColors.BgColorWhite,),
        ),
      ],
    );
  }
}
