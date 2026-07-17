import 'package:account_manager/module/service/database_controller.dart';
import 'package:account_manager/core/app_theme.dart';
import 'package:account_manager/core/app_text_field.dart';
import 'package:account_manager/model/account_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class DashboardController extends GetxController {
  final dataBaseController = Get.find<DatabaseController>();

  Box box = Hive.box("Account");

  ScrollController scrollController = ScrollController();
  final TextEditingController account = TextEditingController();

  RxBool isAmountVisible = true.obs;
  RxnString errorText = RxnString();

  @override
  void onInit() {
    super.onInit();
    isAmountVisible.value = box.get('isAmountVisible', defaultValue: true);
  }

  // Avatar colors defined here
  final List<Color> avatarBgColors = [
    const Color(0xFFE8F5E9), // Light green
    const Color(0xFFE3F2FD), // Light blue
    const Color(0xFFFFF3E0), // Light orange
    const Color(0xFFF3E5F5), // Light purple
    const Color(0xFFFFEBEE), // Light red
    const Color(0xFFE0F7FA), // Light cyan
  ];

  final List<Color> avatarTextColors = [
    const Color(0xFF2E7D32),
    const Color(0xFF1565C0),
    const Color(0xFFEF6C00),
    const Color(0xFF6A1B9A),
    const Color(0xFFC62828),
    const Color(0xFF00838F),
  ];

  List<AccountModel> get getData => dataBaseController.getData;

  void toggleAmountVisibility() {
    isAmountVisible.value = !isAmountVisible.value;
    box.put('isAmountVisible', isAmountVisible.value);
  }

  void accountDialog(context, int id, String name) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        if (id != 0) {
          account.text = name;
        }
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Title Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MyColors.primaryColor, MyColors.primaryColor.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  (id == 0) ? "Add New Account" : "Update Account",
                  style: const TextStyle(
                    fontFamily: Fonts.poppinsSemiBold,
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => AppTextField(
                        controller: account,
                        labelText: "Account Name",
                        prefixIcon: Icons.person_outline_rounded,
                        errorText: errorText.value,
                        onChanged: (val) {
                          if (errorText.value != null) {
                            errorText.value = null;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MyColors.primaryColor,
                              side: BorderSide(color: MyColors.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              account.clear();
                              errorText.value = null;
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              String name = account.text.trim();
                              if (name.isEmpty) {
                                errorText.value = 'Enter Account Name';
                                return;
                              }
                              if (id == 0) {
                                dataBaseController.insertData(name);
                              } else {
                                dataBaseController.updateData(name, id);
                              }
                              Navigator.pop(context);
                              account.clear();
                              errorText.value = null;
                              dataBaseController.selectData();
                            },
                            child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
