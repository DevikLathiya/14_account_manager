  import 'package:account_manager/core/app_theme.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String title, String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontFamily: Fonts.poppinsSemiBold, fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              message,
              style: TextStyle(fontFamily: Fonts.poppinsMedium, color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : MyColors.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }