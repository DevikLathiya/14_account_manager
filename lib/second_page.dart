import 'dart:io';

import 'package:account_manager/core/app_theme.dart';
import 'package:account_manager/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/shape/gf_button_shape.dart';
import 'package:getwidget/types/gf_button_type.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';
import 'Controller Screen/GetXController.dart';
import 'package:path/path.dart';

class SecondPage extends StatefulWidget {
  static Database? database;

  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  MyController data = Get.put(MyController());
  final TextEditingController _answer1 = TextEditingController();
  final TextEditingController _answer2 = TextEditingController();
  final TextEditingController _newPass = TextEditingController();

  var selectedindex = 0;
  String code = '';
  String password = '';
  Box box = Hive.box("Account");

  dataTable() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'AccountManager.db');

    SecondPage.database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('CREATE TABLE Account (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, credit TEXT, debit TEXT, balance TEXT)');
        await db.execute('CREATE TABLE MyTransaction (id INTEGER PRIMARY KEY,date TEXT , AcId INTEGER, detail TEXT, credit TEXT, debit TEXT)');
      },
    );

    data.selectData();

    final tables = await SecondPage.database!.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'Account']);
    (tables.isNotEmpty) ? print('Table exists!') : print('Table does not exist!');

    final table = await SecondPage.database!.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'MyTransaction']);
    (table.isNotEmpty) ? print('Table exists!') : print('Table does not exist!');
  }

  @override
  void initState() {
    super.initState();
    dataTable();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: MyColors.secondaryColor,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            MyColors.secondaryColor,
            MyColors.primaryColor
          ],
          begin: AlignmentGeometry.topLeft,end: AlignmentGeometry.bottomRight
          )
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset("assets/images/logo.png", height: 80)),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      "Account Manager",
                      style: TextStyle(fontSize: 23, color: Colors.black.withBlue(100), fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            insetPadding: EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                                  alignment: Alignment.center,
                                  child: Text("Forgot Password?", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  "➽ Give following  Security questions answer for reset password.",
                                  style: Theme.of(context).poppinsRegular.copyWith(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text("➽ ${box.get("Question1")}", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                                TextField(
                                  controller: _answer1,
                                  decoration: InputDecoration(
                                    hintText: "Answer",
                                    hintStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text("➽ ${box.get("Question2")}", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                                TextField(
                                  controller: _answer2,
                                  decoration: InputDecoration(
                                    hintText: "Answer",
                                    hintStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    GFButton(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      text: "Cancel",
                                      textStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.primaryColor),
                                      type: GFButtonType.outline,
                                      shape: GFButtonShape.pills,
                                      color: MyColors.primaryColor,
                                    ),
                                    GFButton(
                                      onPressed: () {
                                        if (_answer1.text.isEmpty || _answer2.text.isEmpty) {
                                          Fluttertoast.showToast(
                                            msg: "Enter Answer",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.SNACKBAR,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: MyColors.primaryColor,
                                            textColor: Colors.white,
                                            fontSize: 16.0,
                                          );
                                        } else {
                                          if (_answer1.text == box.get("answer1") && _answer2.text == box.get("answer2")) {
                                            Get.back();
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: Container(
                                                    width: double.infinity,
                                                    height: 50,
                                                    decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      "Set new Password",
                                                      style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white),
                                                    ),
                                                  ),
                                                  content: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        inputFormatters: [LengthLimitingTextInputFormatter(4), FilteringTextInputFormatter.digitsOnly],
                                                        controller: _newPass,
                                                        keyboardType: TextInputType.phone,
                                                        decoration: InputDecoration(
                                                          hintText: "New Password",
                                                          hintStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 20),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                        children: [
                                                          GFButton(
                                                            onPressed: () {
                                                              Get.back();
                                                            },
                                                            text: "cancel",
                                                            type: GFButtonType.outline,
                                                            shape: GFButtonShape.pills,
                                                            color: MyColors.primaryColor,
                                                            textStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.primaryColor),
                                                          ),
                                                          GFButton(
                                                            onPressed: () {
                                                              if (_newPass.text.isEmpty) {
                                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter Password")));
                                                              } else if (_newPass.text.length <= 3) {
                                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter Valid Password")));
                                                              } else {
                                                                box.put('password', _newPass.text);
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(const SnackBar(content: Text("Successfully Reset Password")));
                                                                Get.back();
                                                              }
                                                            },
                                                            text: "Set",
                                                            textStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.white),
                                                            shape: GFButtonShape.pills,
                                                            color: MyColors.primaryColor,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          } else {
                                            Fluttertoast.showToast(
                                              msg: "Incorrect Answer",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.SNACKBAR,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: MyColors.primaryColor,
                                              textColor: Colors.white,
                                              fontSize: 16.0,
                                            );
                                          }
                                        }
                                      },
                                      text: "Verify",
                                      textStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.white),
                                      shape: GFButtonShape.pills,
                                      color: MyColors.primaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ).paddingAll(20),
                          );
                        },
                      );
                    },
                    child: Text(
                      "Forget Password",
                      style: TextStyle(fontSize: 15, color: Colors.black.withBlue(40), fontWeight: FontWeight.w300),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DigitHolder(width: width, index: 0, selectedIndex: selectedindex, code: code),

                      DigitHolder(width: width, index: 1, selectedIndex: selectedindex, code: code),

                      DigitHolder(width: width, index: 2, selectedIndex: selectedindex, code: code),

                      DigitHolder(width: width, index: 3, selectedIndex: selectedindex, code: code),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.of(context).padding.bottom + (Platform.isIOS ? 0 : 10)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: NumberPad(),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberPad extends StatelessWidget {
  final controller = Get.find<MyController>();

  final List<String> buttons = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'back', '0', 'done'];

  NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: buttons.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 1.5),
      itemBuilder: (context, index) {
        final value = buttons[index];

        if (value == 'back') {
          return _buildSpecialButton(icon: Icons.backspace_outlined, color: Colors.red.shade400, onTap: controller.backspace);
        } else if (value == 'done') {
          return _buildSpecialButton(
            icon: Icons.check,
            color: Colors.green.shade400,
            onTap: () {
              if (controller.code.value == controller.getPassword().value) {
                Get.offAll(DashboardScreen());
              } else {
                Fluttertoast.showToast(msg: "Wrong Password", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.CENTER);
              }
            },
          );
        } else {
          return _buildDigitButton(value);
        }
      },
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => controller.addDigit(int.parse(digit)),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, offset: Offset(1, 6), blurRadius: 10),
            BoxShadow(color: Colors.grey.shade300, offset: Offset(-1, -2), blurRadius: 15),
          ],
        ),
        child: Text(
          digit,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black.withBlue(40)),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: Colors.black.withBlue(40), size: 30),
      ),
    );
  }
}

class DigitHolder extends StatelessWidget {
  final int selectedIndex;
  final int index;
  final String code;


  DigitHolder({required this.selectedIndex, super.key, required this.width, required this.index, required this.code});

  final double width;

  @override
  Widget build(BuildContext context) {
    return GetX(
      init: MyController(),
      builder: (data) {
        return Container(
          alignment: Alignment.center,
          height: width * 0.17,
          width: width * 0.17,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: data.code.value.length > index ? MyColors.primaryColor : Colors.transparent,width: 2),
          ),
          child: Obx(
            () => data.code.value.length > index
                ? Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(color: Colors.black.withBlue(40), shape: BoxShape.circle),
                  )
                : Container(),
          ),
        );
      }
    );
  }
}
