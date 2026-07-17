import 'dart:io';

import 'package:account_manager/core/app_theme.dart';
import 'package:account_manager/module/dashboard/dashboard_controller.dart';
import 'package:account_manager/module/dashboard/dashboard_screen.dart';
import 'package:account_manager/module/setting/bottom_bar_controller.dart';
import 'package:account_manager/module/setting/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomBarScreen extends StatelessWidget {
  const BottomBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX(
      init: BottomBarController(),
      builder: (controller) {
        return Scaffold(
          body: Stack(
            children: [
              Obx(() {
                final index = controller.currentIndex.value;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    AnimatedSlide(
                      offset: index == 0 ? Offset.zero : const Offset(-1.0, 0.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      child: IgnorePointer(
                        ignoring: index != 0,
                        child: const DashboardScreen(),
                      ),
                    ),
                    AnimatedSlide(
                      offset: index == 1 ? Offset.zero : const Offset(1.0, 0.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      child: IgnorePointer(
                        ignoring: index != 1,
                        child: const SettingsScreen(),
                      ),
                    ),
                  ],
                );
              }),
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + (Platform.isAndroid ? 10 : 0),
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildNavItem(context, index: 0, icon: Icons.home_rounded, label: "Home", isSelected: controller.currentIndex.value == 0, controller: controller),
                            const SizedBox(width: 4),
                            _buildNavItem(
                              context,
                              index: 1,
                              icon: Icons.settings_rounded,
                              label: "Settings",
                              isSelected: controller.currentIndex.value == 1,
                              controller: controller,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        heroTag: 'fab_add_acc_main',
                        backgroundColor: MyColors.primaryColor,
                        tooltip: "Add Account",
                        onPressed: () {
                          if (Get.isRegistered<DashboardController>()) {
                            Get.find<DashboardController>().accountDialog(context, 0, "");
                          }
                        },
                        child: const Icon(Icons.add, size: 30, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required BottomBarController controller,
  }) {
    return GestureDetector(
      onTap: () => controller.changePage(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? MyColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MyColors.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (value * 0.1),
                    child: Icon(
                      icon,
                      color: isSelected ? MyColors.white : MyColors.grey,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: Fonts.poppinsMedium,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? MyColors.white : MyColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
