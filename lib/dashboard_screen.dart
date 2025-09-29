import 'package:account_manager/Controller%20Screen/GetXController.dart';
import 'package:account_manager/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/shape/gf_button_shape.dart';
import 'package:getwidget/types/gf_button_type.dart';
import 'package:hive/hive.dart';
import 'balance_detail.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _account = TextEditingController();
  final TextEditingController _oldPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _answer1 = TextEditingController();
  final TextEditingController _answer2 = TextEditingController();

  String? _selected1, _selected2;
  Box box = Hive.box("Account");

  List<String> question1 = [
    "What was the first mobile that you purchased?",
    "What was the name of your best friend at childhood?",
    "What was the name of your first pet?",
    "What is your favourite children's book?",
    "What was the first film you saw in the cinema?",
    "What was the name of your favourite teacher in school?",
  ];
  List<String> question2 = [
    "What is the name of your favourite sports team?",
    "Who was your favourite singer or band?",
    " What is your first job?",
    "What was the first dish you learned to cook?",
    "What was the model of your first motorised vehicle?",
    "What was your childhood nickname?",
  ];

  @override
  Widget build(BuildContext context) {
    return GetX(
      init: MyController(),
      initState: (state) => state.controller?.totalStatement(),
      builder: (controller) {
        controller.index.value;
        return Scaffold(
          body: CustomScrollView(
            controller: controller.scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(floating: false, pinned: true, delegate: CustomSliverAppBarDelegate(expandedHeight: 250, controller: controller)),
              SliverList(delegate: SliverChildListDelegate([SizedBox(height: 60), SizedBox()])),

              controller.getData.isEmpty
                  ? SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 50),
                            Text("No Data Found", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20)),
                            SizedBox(height: 4),
                            Text("Click On Add Button to add Account.", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  : SliverList.separated(
                      itemCount: controller.getData.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade300, endIndent: 20, indent: 20).paddingSymmetric(vertical: 20),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          child: Slidable(
                            key: ValueKey("player.id"),
                            endActionPane: ActionPane(
                              motion: ScrollMotion(),
                              extentRatio: 0.35,
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    accountDialog(controller.getData[index]['id'], controller.getData[index]['name'], controller);
                                  },
                                  icon: Icons.edit,
                                  autoClose: true,
                                  padding: EdgeInsets.zero,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                SizedBox(width: 10),
                                SlidableAction(
                                  onPressed: (context) {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text("Are Want To Delete?", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
                                          actions: [
                                            GFButton(
                                              onPressed: () {
                                                Get.back();
                                              },
                                              text: "cancel",
                                              textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                                              type: GFButtonType.outline,
                                              shape: GFButtonShape.pills,
                                              color: MyColors.primaryColor,
                                            ),
                                            GFButton(
                                              onPressed: () {
                                                controller.deleteData(controller.getData[index]['id']);
                                                controller.totalStatement();
                                                Get.back();
                                              },
                                              text: "Delete",
                                              textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                              shape: GFButtonShape.pills,
                                              color: MyColors.primaryColor,
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  backgroundColor: Colors.red.shade300,
                                  icon: Icons.delete,
                                  autoClose: true,
                                  padding: EdgeInsets.zero,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                SizedBox(width: 10),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () => Get.to(BalanceDetailScreen(controller.getData[index]))?.then((value) => controller.selectData()),
                              child: Container(
                                color: Colors.transparent,
                                padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${controller.getData[index]['name']}",
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18),
                                          ),
                                          Text(
                                            "Credit : ₹ ${controller.getData[index]['credit']} - Debit : ₹ ${controller.getData[index]['debit']}",
                                            style: Theme.of(context).poppinsRegular.copyWith(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text("₹ ${controller.getData[index]['balance']}", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              SliverToBoxAdapter(child: SizedBox(height: 180))
            ],
          ),

          // Column(
          //   children: [
          //     Container(
          //       height: 250,
          //       width: Get.width,
          //       padding: EdgeInsets.only(bottom: 8, top: 20),
          //       decoration: BoxDecoration(
          //         color: MyColors.primaryColor,
          //         borderRadius: BorderRadius.only(
          //           bottomLeft: Radius.circular(50),
          //           bottomRight: Radius.circular(50),
          //         ),
          //       ),
          //       child: Column(
          //         children: [
          //           SizedBox(height: MediaQuery.of(context).padding.top),
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               // GestureDetector(
          //               //   onTap: () => _key.currentState!.openDrawer(),
          //               //   child: Icon(Icons.menu_rounded, color: Colors.white),
          //               // ),
          //               Text(
          //                 "DashBoard",
          //                 textAlign: TextAlign.center,
          //                 style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: Colors.white),
          //               ),
          //               // Icon(Icons.menu_rounded, color: Colors.transparent),
          //             ],
          //           ),
          //           Spacer(),
          //
          //           Text("Overall Balance", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: MyColors.secondaryColor)),
          //           SizedBox(height: 6),
          //
          //           Text(
          //             (controller.mainBalance.value == '') ? "₹00" : "₹ ${controller.mainBalance.value}",
          //             style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: Colors.white),
          //           ),
          //           SizedBox(height: 16),
          //
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //             children: [
          //               // Text("Credit : ", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.secondaryColor)),
          //               // SizedBox(height: 2),
          //               Text(
          //                 (controller.cr.value == "null") ? "₹00" : "₹ ${controller.cr.value}",
          //                 style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.green),
          //               ),
          //
          //               SizedBox(width: 20),
          //
          //               // Text("Debit : ", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.secondaryColor)),
          //               // SizedBox(height: 2),
          //               Text(
          //                 (controller.de.value == "null") ? "₹00" : "₹ ${controller.de.value}",
          //                 style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.red),
          //               ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //
          //     (controller.getData.isEmpty)
          //         ? Expanded(
          //             child: Column(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               children: [
          //                 Icon(Icons.warning, color: Colors.red, size: 50),
          //                 Text("No Data Found", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20)),
          //                 SizedBox(height: 4),
          //                 Text("Click On Add Button to add Account.", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
          //               ],
          //             ),
          //           )
          //         : Expanded(
          //             child: Container(
          //               margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
          //               child: ListView.separated(
          //                 itemCount: controller.getData.length,
          //                 padding: EdgeInsets.only(bottom: 150),
          //                 separatorBuilder: (context, index) {
          //                   return Divider(height: 1, color: Colors.grey.shade300, endIndent: 20, indent: 20).paddingSymmetric(vertical: 20);
          //                 },
          //                 itemBuilder: (context, index) {
          //                   return SizedBox(
          //                     child: Slidable(
          //                       key: ValueKey("player.id"),
          //                       endActionPane: ActionPane(
          //                         motion: ScrollMotion(),
          //                         extentRatio: 0.35,
          //                         children: [
          //                           SlidableAction(
          //                             onPressed: (context) {
          //                               accountDialog(controller.getData[index]['id'], controller.getData[index]['name'], controller);
          //                             },
          //                             icon: Icons.edit,
          //                             autoClose: true,
          //                             padding: EdgeInsets.zero,
          //                             borderRadius: BorderRadius.circular(100),
          //                           ),
          //                           SizedBox(width: 10),
          //                           SlidableAction(
          //                             onPressed: (context) {
          //                               showDialog(
          //                                 context: context,
          //                                 builder: (context) {
          //                                   return AlertDialog(
          //                                     title: Text("Are Want To Delete?", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
          //                                     actions: [
          //                                       GFButton(
          //                                         onPressed: () {
          //                                           Get.back();
          //                                         },
          //                                         text: "cancel",
          //                                         textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
          //                                         type: GFButtonType.outline,
          //                                         shape: GFButtonShape.pills,
          //                                         color: MyColors.primaryColor,
          //                                       ),
          //                                       GFButton(
          //                                         onPressed: () {
          //                                           controller.deleteData(controller.getData[index]['id']);
          //                                           controller.totalStatement();
          //                                           Get.back();
          //                                         },
          //                                         text: "Delete",
          //                                         textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
          //                                         shape: GFButtonShape.pills,
          //                                         color: MyColors.primaryColor,
          //                                       ),
          //                                     ],
          //                                   );
          //                                 },
          //                               );
          //                             },
          //                             backgroundColor: Colors.red.shade300,
          //                             icon: Icons.delete,
          //                             autoClose: true,
          //                             padding: EdgeInsets.zero,
          //                             borderRadius: BorderRadius.circular(100),
          //                           ),
          //                           SizedBox(width: 10),
          //                         ],
          //                       ),
          //                       child: GestureDetector(
          //                         onTap: () => Get.to(BalanceDetailScreen(controller.getData[index]))?.then((value) => controller.selectData()),
          //                         child: Container(
          //                           color: Colors.transparent,
          //                           padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
          //                           child: Row(
          //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                             children: [
          //                               Expanded(
          //                                 child: Column(
          //                                   crossAxisAlignment: CrossAxisAlignment.start,
          //                                   children: [
          //                                     Text(
          //                                       "${controller.getData[index]['name']}",
          //                                       maxLines: 1,
          //                                       overflow: TextOverflow.fade,
          //                                       style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18),
          //                                     ),
          //                                     Text(
          //                                       "Credit : ₹ ${controller.getData[index]['credit']} - Debit : ₹ ${controller.getData[index]['debit']}",
          //                                       style: Theme.of(context).poppinsRegular.copyWith(fontSize: 12),
          //                                     ),
          //                                   ],
          //                                 ),
          //                               ),
          //                               SizedBox(width: 10),
          //                               Text("₹ ${controller.getData[index]['balance']}", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
          //                             ],
          //                           ),
          //                         ),
          //                       ),
          //                     ),
          //                   );
          //
          //                   // return InkWell(
          //                   //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BalanceDetail(controller.getData[index])))?.then((value) => controller.totalstatement()),
          //                   //   child: Card(
          //                   //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          //                   //     elevation: 8,
          //                   //     child: SizedBox(
          //                   //       height: height * 0.165,
          //                   //       width: double.infinity,
          //                   //       child: Column(
          //                   //         children: [
          //                   //           Row(
          //                   //             children: [
          //                   //               Container(
          //                   //                 margin: const EdgeInsets.fromLTRB(10, 0, 0, 5),
          //                   //                 child: Text("${controller.getData[index]['name']}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
          //                   //               ),
          //                   //               const Spacer(),
          //                   //               IconButton(
          //                   //                 onPressed: () {
          //                   //                   accountData(controller.getData[index]['id'], controller.getData[index]['name']);
          //                   //                 },
          //                   //                 icon: const Icon(Icons.edit, size: 20),
          //                   //               ),
          //                   //
          //                   //               IconButton(
          //                   //                 onPressed: () {
          //                   //                   showDialog(
          //                   //                     context: context,
          //                   //                     builder: (context) {
          //                   //                       return AlertDialog(
          //                   //                         title: const Text("Are Want To Delete?"),
          //                   //                         actions: [
          //                   //                           TextButton(
          //                   //                             onPressed: () {
          //                   //                               Get.back();
          //                   //                             },
          //                   //                             child: const Text("Cancel"),
          //                   //                           ),
          //                   //                           TextButton(
          //                   //                             onPressed: () {
          //                   //                               controller.delateData(controller.getData[index]['id']);
          //                   //                               controller.totalstatement();
          //                   //                               Get.back();
          //                   //                             },
          //                   //                             child: const Text("Delete"),
          //                   //                           ),
          //                   //                         ],
          //                   //                       );
          //                   //                     },
          //                   //                   );
          //                   //                 },
          //                   //                 icon: const Icon(Icons.delete, size: 20),
          //                   //               ),
          //                   //             ],
          //                   //           ),
          //                   //           Row(
          //                   //             children: [
          //                   //               Container(
          //                   //                 height: height * 0.080,
          //                   //                 width: width * 0.27,
          //                   //                 margin: const EdgeInsets.fromLTRB(9, 7, 5, 7),
          //                   //                 decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
          //                   //                 child: Column(
          //                   //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //                   //                   children: [
          //                   //                     const Text("Credit(+)", style: TextStyle(fontSize: 16)),
          //                   //                     Text("₹ ${controller.getData[index]['credit']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          //                   //                   ],
          //                   //                 ),
          //                   //               ),
          //                   //               Container(
          //                   //                 height: height * 0.080,
          //                   //                 width: width * 0.27,
          //                   //                 margin: const EdgeInsets.fromLTRB(7, 7, 5, 7),
          //                   //                 decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
          //                   //                 child: Column(
          //                   //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //                   //                   children: [
          //                   //                     const Text("Debit(-)", style: TextStyle(fontSize: 16)),
          //                   //                     Text("₹ ${controller.getData[index]['debit']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          //                   //                   ],
          //                   //                 ),
          //                   //               ),
          //                   //               Container(
          //                   //                 height: height * 0.080,
          //                   //                 width: width * 0.27,
          //                   //                 margin: const EdgeInsets.fromLTRB(7, 7, 5, 7),
          //                   //                 decoration: BoxDecoration(color: Colors.blue.shade300, borderRadius: BorderRadius.circular(12)),
          //                   //                 child: Column(
          //                   //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //                   //                   children: [
          //                   //                     const Text("Balance", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
          //                   //                     Text(
          //                   //                       "₹ ${controller.getData[index]['balance']}",
          //                   //                       style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
          //                   //                     ),
          //                   //                   ],
          //                   //                 ),
          //                   //               ),
          //                   //             ],
          //                   //           ),
          //                   //         ],
          //                   //       ),
          //                   //     ),
          //                   //   ),
          //                   // );
          //                 },
          //               ),
          //             ),
          //           ),
          //   ],
          // ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                mini: true,
                backgroundColor: MyColors.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(100)),
                tooltip: "Setting",
                onPressed: () => settingDialog(),
                child: const Icon(Icons.settings, size: 20, color: Colors.white),
              ),
              SizedBox(height: 10),
              FloatingActionButton(
                backgroundColor: MyColors.primaryColor,
                tooltip: "Add Account",
                onPressed: () => accountDialog(0, "", controller),
                child: const Icon(Icons.add, size: 40, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  void accountDialog(int id, String name, MyController controller) {
    showDialog(
      context: context,
      builder: (context) {
        if (id != 0) {
          _account.text = name;
        }
        return Dialog(
          insetPadding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 50,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  (id == 0) ? "Add New Account" : "Update Account",
                  style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _account,
                decoration: const InputDecoration(label: Text("Account Name")),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GFButton(
                    onPressed: () {
                      _account.clear();
                      Get.back();
                    },
                    text: "cancel",
                    textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                    type: GFButtonType.outline,
                    shape: GFButtonShape.pills,
                    color: MyColors.primaryColor,
                  ),
                  GFButton(
                    onPressed: () {
                      String name = _account.text;
                      if (id == 0) {
                        if (name.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Enter Account Name",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: MyColors.primaryColor,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        } else {
                          controller.insertData(name);
                          Get.back();
                        }
                      } else {
                        controller.updateData(name, id);
                        Get.back();
                      }
                      _account.clear();
                      controller.selectData();
                    },
                    text: "Save",
                    textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
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
  }

  void settingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 50,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text("Setting", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.key),
                title: Text("Change Password", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                onTap: () => [Get.back(), changePass()],
              ),
              ListTile(
                leading: const Icon(Icons.question_answer),
                title: Text("Change Security Question", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                onTap: () => [Get.back(), changeQuestion()],
              ),
            ],
          ).paddingAll(20),
        );
      },
    );
  }

  void changePass() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text("Change Password?", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _oldPass,
                keyboardType: TextInputType.phone,
                inputFormatters: [LengthLimitingTextInputFormatter(4), FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "Current Password",
                  hintStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _newPass,
                keyboardType: TextInputType.phone,
                inputFormatters: [LengthLimitingTextInputFormatter(4), FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "New Password",
                  hintStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GFButton(
                    onPressed: () => Get.back(),
                    text: "Cancel",
                    textStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.primaryColor),
                    type: GFButtonType.outline,
                    shape: GFButtonShape.pills,
                    color: MyColors.primaryColor,
                  ),
                  GFButton(
                    onPressed: () {
                      if (_oldPass.text.isEmpty || _newPass.text.isEmpty) {
                        Fluttertoast.showToast(
                          msg: "Enter Password",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.cyan,
                          textColor: Colors.black,
                          fontSize: 16.0,
                        );
                      } else {
                        if (_oldPass.text == box.get("password")) {
                          box.put('password', _newPass.text);
                          Fluttertoast.showToast(
                            msg: "Successfully Reset Password",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.SNACKBAR,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.cyan,
                            textColor: Colors.black,
                            fontSize: 16.0,
                          );
                          _oldPass.clear();
                          _newPass.clear();
                          Get.back();
                        } else {
                          Fluttertoast.showToast(
                            msg: "Incorrect Answer",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.SNACKBAR,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.cyan,
                            textColor: Colors.black,
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
  }

  void changeQuestion() {
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
                alignment: Alignment.center,
                decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text("Change Security Questions", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 10),
              Text(
                "➽ Change Security questions for retrieve your password when you forgot.",
                style: Theme.of(context).poppinsRegular.copyWith(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              DropdownButton(
                isExpanded: true,
                hint: Text('Security Question 1', style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                value: _selected1,
                onChanged: (newValue) {
                  setState(() {
                    _selected1 = newValue;
                  });
                },
                items: question1.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location, style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                  );
                }).toList(),
              ),
              TextField(
                controller: _answer1,
                decoration: InputDecoration(
                  hintText: "Answer",
                  hintStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                ),
              ),
              SizedBox(height: 10),
              DropdownButton(
                isExpanded: true,
                hint: Text('Security Question 2', style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                value: _selected2,
                onChanged: (newValue) {
                  setState(() {
                    _selected2 = newValue;
                  });
                },
                items: question2.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location, style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                  );
                }).toList(),
              ),
              TextField(
                controller: _answer2,
                decoration: InputDecoration(
                  hintText: "Answer",
                  hintStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
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
                      if (_selected1 == null || _selected2 == null) {
                        Fluttertoast.showToast(
                          msg: "Enter Security Question",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          backgroundColor: MyColors.primaryColor,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      } else if (_answer1.text.isEmpty || _answer2.text.isEmpty) {
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
                        String question1 = _selected1!, question2 = _selected2!;
                        String answer1 = _answer1.text, answer2 = _answer2.text;

                        box.put("Question1", question1);
                        box.put("Question2", question2);
                        box.put("answer1", answer1);
                        box.put("answer2", answer2);
                        Get.back();
                        _answer1.clear();
                        _answer2.clear();
                        // _selected1="";
                        // _selected2="";
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
  }
}

class CustomSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final MyController controller;

  const CustomSliverAppBarDelegate({required this.expandedHeight, required this.controller});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double floatingHeight = 120;
    final double maxPadding = 20;
    final double minPadding = 0;

    final double horizontalPadding = (maxPadding * (1 - shrinkOffset / expandedHeight)).clamp(minPadding, maxPadding);

    final double top = (expandedHeight - floatingHeight - shrinkOffset).clamp(0, expandedHeight - floatingHeight);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        buildTopBar(shrinkOffset, context, top),
        Positioned(top: top, left: horizontalPadding, right: horizontalPadding, child: buildFloating(context, controller, shrinkOffset)),
      ],
    );
  }

  Widget buildTopBar(double shrinkOffset, context, double top) {
    final opacity = (1 - shrinkOffset / expandedHeight).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Container(
        height: expandedHeight,
        width: Get.width,
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: 60, top: 0),
        decoration: BoxDecoration(
          color: MyColors.primaryColor,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
        ),
        child: Text("DashBoard", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: MyColors.white)),
      ),
    );
  }

  Widget buildFloating(context, controller, double shrinkOffset) {
    final double progress = (shrinkOffset / expandedHeight).clamp(0.0, 1.0);

    final double baseHeight = expandedHeight / 1.6;
    final double maxExtraHeight = 30;
    final double dynamicHeight = baseHeight + (maxExtraHeight * progress);

    return AnimatedContainer(
      padding: EdgeInsets.only(left: 20, right: 20),
      height: dynamicHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      duration: Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Overall Balance", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: MyColors.primaryColor)),
          SizedBox(height: 6),

          Text(
            (controller.mainBalance.value == '') ? "₹00" : "₹ ${controller.mainBalance.value}",
            style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: MyColors.primaryColor),
          ),
          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.only(bottom: 10, top: 10,left: 10,right: 10),
            margin: EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Text(
                    textAlign: TextAlign.center,
                    (controller.cr.value == "null") ? "₹00" : "₹ ${controller.cr.value}",
                    style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.green),
                  ),
                ),

                Container(color: Colors.grey.shade300,height: 20,width: 1),

                Expanded(
                  child: Text(
                    textAlign: TextAlign.center,
                    (controller.de.value == "null") ? "₹00" : "₹ ${controller.de.value}",
                    style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 30;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

/*class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _account = TextEditingController();
  final TextEditingController _oldPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _answer1 = TextEditingController();
  final TextEditingController _answer2 = TextEditingController();

  String? _selected1, _selected2;
  Box box = Hive.box("Account");

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  List<String> question1 = [
    "What was the first mobile that you purchased?",
    "What was the name of your best friend at childhood?",
    "What was the name of your first pet?",
    "What is your favourite children's book?",
    "What was the first film you saw in the cinema?",
    "What was the name of your favourite teacher in school?",
  ];
  List<String> question2 = [
    "What is the name of your favourite sports team?",
    "Who was your favourite singer or band?",
    " What is your first job?",
    "What was the first dish you learned to cook?",
    "What was the model of your first motorised vehicle?",
    "What was your childhood nickname?",
  ];


  @override
  Widget build(BuildContext context) {
    return GetX(
      init: MyController(),
      initState: (state) => state.controller?.totalStatement(),
      builder: (controller) {
        return Scaffold(
          key: _key,
          drawer: Drawer(
            width: 270,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3,
              margin: const EdgeInsets.only(right: 6, bottom: 6),
              decoration: BoxDecoration(color: Colors.cyan.shade100, borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 50),
                  ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset("assets/images/logo.png", height: 50)),
                  SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text("Account Manager", style: TextStyle(fontSize: 25)),
                  ),
                  Container(height: 1, color: Colors.white, margin: const EdgeInsets.symmetric(vertical: 10)),

                  Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 5,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text("Credit", style: TextStyle(fontSize: 17)),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 15, 10),
                                child: Obx(
                                  () => Text((controller.cr.value == "null") ? "₹00" : "₹ ${controller.cr.value}", style: const TextStyle(fontSize: 17)),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text("Debit", style: TextStyle(fontSize: 17)),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 15, 10),
                                child: Obx(
                                  () => Text((controller.de.value == "null") ? "₹00" : "₹ ${controller.de.value}", style: const TextStyle(fontSize: 17)),
                                ),
                              ),
                            ],
                          ),
                          Container(height: 1, color: Colors.white),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text("Balance", style: TextStyle(fontSize: 17)),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 15, 10),
                                child: Obx(
                                  () => Text(
                                    (controller.mainBalance.value == '') ? "₹00" : "₹ ${controller.mainBalance.value}",
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(leading: const Icon(Icons.key), title: const Text("Change Password"), onTap: () => changePass()),
                  ListTile(leading: const Icon(Icons.question_answer), title: const Text("Change Security Question"), onTap: () => changeQuestion()),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                height: 250,
                width: Get.width,
                padding: EdgeInsets.only(bottom: 8, top: 20),
                decoration: BoxDecoration(
                  color: MyColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // GestureDetector(
                        //   onTap: () => _key.currentState!.openDrawer(),
                        //   child: Icon(Icons.menu_rounded, color: Colors.white),
                        // ),
                        Text(
                          "DashBoard",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: Colors.white),
                        ),
                        // Icon(Icons.menu_rounded, color: Colors.transparent),
                      ],
                    ),
                    Spacer(),

                    Text("Overall Balance", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: MyColors.secondaryColor)),
                    SizedBox(height: 6),

                    Text(
                      (controller.mainBalance.value == '') ? "₹00" : "₹ ${controller.mainBalance.value}",
                      style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Text("Credit : ", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.secondaryColor)),
                        // SizedBox(height: 2),
                        Text(
                          (controller.cr.value == "null") ? "₹00" : "₹ ${controller.cr.value}",
                          style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.green),
                        ),

                        SizedBox(width: 20),

                        // Text("Debit : ", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: MyColors.secondaryColor)),
                        // SizedBox(height: 2),
                        Text(
                          (controller.de.value == "null") ? "₹00" : "₹ ${controller.de.value}",
                          style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              (controller.getData.isEmpty)
                  ? Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 50),
                          Text("No Data Found", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20)),
                          SizedBox(height: 4),
                          Text("Click On Add Button to add Account.", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                        ],
                      ),
                    )
                  : Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                        child: ListView.separated(
                          itemCount: controller.getData.length,
                          padding: EdgeInsets.only(bottom: 150),
                          separatorBuilder: (context, index) {
                            return Divider(height: 1, color: Colors.grey.shade300, endIndent: 20, indent: 20).paddingSymmetric(vertical: 20);
                          },
                          itemBuilder: (context, index) {
                            return SizedBox(
                              child: Slidable(
                                key: ValueKey("player.id"),
                                endActionPane: ActionPane(
                                  motion: ScrollMotion(),
                                  extentRatio: 0.35,
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        accountDialog(controller.getData[index]['id'], controller.getData[index]['name'], controller);
                                      },
                                      icon: Icons.edit,
                                      autoClose: true,
                                      padding: EdgeInsets.zero,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    SizedBox(width: 10),
                                    SlidableAction(
                                      onPressed: (context) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text("Are Want To Delete?", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
                                              actions: [
                                                GFButton(
                                                  onPressed: () {
                                                    Get.back();
                                                  },
                                                  text: "cancel",
                                                  textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                                                  type: GFButtonType.outline,
                                                  shape: GFButtonShape.pills,
                                                  color: MyColors.primaryColor,
                                                ),
                                                GFButton(
                                                  onPressed: () {
                                                    controller.deleteData(controller.getData[index]['id']);
                                                    controller.totalStatement();
                                                    Get.back();
                                                  },
                                                  text: "Delete",
                                                  textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                                  shape: GFButtonShape.pills,
                                                  color: MyColors.primaryColor,
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      backgroundColor: Colors.red.shade300,
                                      icon: Icons.delete,
                                      autoClose: true,
                                      padding: EdgeInsets.zero,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: () => Get.to(BalanceDetailScreen(controller.getData[index]))?.then((value) => controller.selectData()),
                                  child: Container(
                                    color: Colors.transparent,
                                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${controller.getData[index]['name']}",
                                                maxLines: 1,
                                                overflow: TextOverflow.fade,
                                                style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18),
                                              ),
                                              Text(
                                                "Credit : ₹ ${controller.getData[index]['credit']} - Debit : ₹ ${controller.getData[index]['debit']}",
                                                style: Theme.of(context).poppinsRegular.copyWith(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text("₹ ${controller.getData[index]['balance']}", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );

                            // return InkWell(
                            //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BalanceDetail(controller.getData[index])))?.then((value) => controller.totalstatement()),
                            //   child: Card(
                            //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            //     elevation: 8,
                            //     child: SizedBox(
                            //       height: height * 0.165,
                            //       width: double.infinity,
                            //       child: Column(
                            //         children: [
                            //           Row(
                            //             children: [
                            //               Container(
                            //                 margin: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                            //                 child: Text("${controller.getData[index]['name']}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
                            //               ),
                            //               const Spacer(),
                            //               IconButton(
                            //                 onPressed: () {
                            //                   accountData(controller.getData[index]['id'], controller.getData[index]['name']);
                            //                 },
                            //                 icon: const Icon(Icons.edit, size: 20),
                            //               ),
                            //
                            //               IconButton(
                            //                 onPressed: () {
                            //                   showDialog(
                            //                     context: context,
                            //                     builder: (context) {
                            //                       return AlertDialog(
                            //                         title: const Text("Are Want To Delete?"),
                            //                         actions: [
                            //                           TextButton(
                            //                             onPressed: () {
                            //                               Get.back();
                            //                             },
                            //                             child: const Text("Cancel"),
                            //                           ),
                            //                           TextButton(
                            //                             onPressed: () {
                            //                               controller.delateData(controller.getData[index]['id']);
                            //                               controller.totalstatement();
                            //                               Get.back();
                            //                             },
                            //                             child: const Text("Delete"),
                            //                           ),
                            //                         ],
                            //                       );
                            //                     },
                            //                   );
                            //                 },
                            //                 icon: const Icon(Icons.delete, size: 20),
                            //               ),
                            //             ],
                            //           ),
                            //           Row(
                            //             children: [
                            //               Container(
                            //                 height: height * 0.080,
                            //                 width: width * 0.27,
                            //                 margin: const EdgeInsets.fromLTRB(9, 7, 5, 7),
                            //                 decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                            //                   children: [
                            //                     const Text("Credit(+)", style: TextStyle(fontSize: 16)),
                            //                     Text("₹ ${controller.getData[index]['credit']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            //                   ],
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: height * 0.080,
                            //                 width: width * 0.27,
                            //                 margin: const EdgeInsets.fromLTRB(7, 7, 5, 7),
                            //                 decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                            //                   children: [
                            //                     const Text("Debit(-)", style: TextStyle(fontSize: 16)),
                            //                     Text("₹ ${controller.getData[index]['debit']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            //                   ],
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: height * 0.080,
                            //                 width: width * 0.27,
                            //                 margin: const EdgeInsets.fromLTRB(7, 7, 5, 7),
                            //                 decoration: BoxDecoration(color: Colors.blue.shade300, borderRadius: BorderRadius.circular(12)),
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //                   children: [
                            //                     const Text("Balance", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
                            //                     Text(
                            //                       "₹ ${controller.getData[index]['balance']}",
                            //                       style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // );
                          },
                        ),
                      ),
                    ),
            ],
          ),

          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                mini: true,
                backgroundColor: MyColors.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(100)),
                tooltip: "Setting",
                onPressed: () => settingDialog(),
                child: const Icon(Icons.settings, size: 20, color: Colors.white),
              ),
              SizedBox(height: 10),
              FloatingActionButton(
                backgroundColor: MyColors.primaryColor,
                tooltip: "Add Account",
                onPressed: () => accountDialog(0, "", controller),
                child: const Icon(Icons.add, size: 40, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  void accountDialog(int id, String name, MyController controller) {
    showDialog(
      context: context,
      builder: (context) {
        if (id != 0) {
          _account.text = name;
        }
        return AlertDialog(
          title: Container(
            height: 50,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
            child: Text((id == 0) ? "Add New Account" : "Update Account", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
          ),
          content: SizedBox(
            height: 115,
            child: Column(
              children: [
                TextField(
                  controller: _account,
                  decoration: const InputDecoration(label: Text("Account Name")),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GFButton(
                      onPressed: () {
                        _account.clear();
                        Get.back();
                      },
                      text: "cancel",
                      textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                      type: GFButtonType.outline,
                      shape: GFButtonShape.pills,
                      color: MyColors.primaryColor,
                    ),
                    GFButton(
                      onPressed: () {
                        String name = _account.text;
                        if (id == 0) {
                          if (name.isEmpty) {
                            Fluttertoast.showToast(
                              msg: "Enter Account Name",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: MyColors.primaryColor,
                              textColor: Colors.black,
                              fontSize: 16.0,
                            );
                          } else {
                            controller.insertData(name);
                            Get.back();
                          }
                        } else {
                          controller.updateData(name, id);
                          Get.back();
                        }
                        _account.clear();
                        controller.selectData();
                      },
                      text: "Save",
                      textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      shape: GFButtonShape.pills,
                      color: MyColors.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void settingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 50,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text("Setting", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.key),
                title: Text("Change Password", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                onTap: () => changePass(),
              ),
              ListTile(
                leading: const Icon(Icons.question_answer),
                title: Text("Change Security Question", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                onTap: () => changeQuestion(),
              ),
            ],
          ).paddingAll(20),
        );
      },
    );
  }

  void changePass() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Container(width: double.infinity, height: 40, color: Colors.cyan, alignment: Alignment.center, child: const Text("Change Password?")),
          content: SizedBox(
            height: 165,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _oldPass,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(4)],
                  decoration: const InputDecoration(hintText: "Current Password"),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _newPass,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(4)],
                  decoration: const InputDecoration(hintText: "New Password"),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GFButton(
                      onPressed: () => Get.back(),
                      text: "cancel",
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 15),
                      type: GFButtonType.outline,
                      shape: GFButtonShape.pills,
                      color: Colors.cyan,
                    ),
                    GFButton(
                      onPressed: () {
                        if (_oldPass.text.isEmpty || _newPass.text.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Enter Password",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.cyan,
                            textColor: Colors.black,
                            fontSize: 16.0,
                          );
                        } else {
                          if (_oldPass.text == box.get("password")) {
                            box.put('password', _newPass.text);
                            Fluttertoast.showToast(
                              msg: "Successfully Reset Password",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.SNACKBAR,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.cyan,
                              textColor: Colors.black,
                              fontSize: 16.0,
                            );
                            _oldPass.clear();
                            _newPass.clear();
                            Get.back();
                          } else {
                            Fluttertoast.showToast(
                              msg: "Incorrect Answer",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.SNACKBAR,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.cyan,
                              textColor: Colors.black,
                              fontSize: 16.0,
                            );
                          }
                        }
                      },
                      text: "Verify",
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      shape: GFButtonShape.pills,
                      color: Colors.cyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void changeQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Container(
            width: double.infinity,
            height: 50,
            color: Colors.cyan,
            alignment: Alignment.center,
            child: const Text("Change Security Questions", style: TextStyle(fontSize: 16)),
          ),
          contentPadding: EdgeInsets.all(10),
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "➽ Change Security questions for retrieve your password when you forgot.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  DropdownButton(
                    isExpanded: true,
                    hint: const Text('Security Question 1'),
                    value: _selected1,
                    onChanged: (newValue) {
                      setState(() {
                        _selected1 = newValue;
                      });
                    },
                    items: question1.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location, style: TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: _answer1,
                    decoration: InputDecoration(hintText: "Answer"),
                  ),
                  SizedBox(height: 10),
                  DropdownButton(
                    isExpanded: true,
                    hint: const Text('Security Question 2'),
                    value: _selected2,
                    onChanged: (newValue) {
                      setState(() {
                        _selected2 = newValue;
                      });
                    },
                    items: question2.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location, style: TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: _answer2,
                    decoration: InputDecoration(hintText: "Answer"),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GFButton(
                        onPressed: () {
                          Get.back();
                        },
                        text: "cancel",
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 15),
                        type: GFButtonType.outline,
                        shape: GFButtonShape.pills,
                        color: Colors.cyan,
                      ),
                      GFButton(
                        onPressed: () {
                          if (_selected1 == null || _selected2 == null) {
                            Fluttertoast.showToast(
                              msg: "Enter Security Question",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.SNACKBAR,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.cyan,
                              textColor: Colors.black,
                              fontSize: 16.0,
                            );
                          } else if (_answer1.text.isEmpty || _answer2.text.isEmpty) {
                            Fluttertoast.showToast(
                              msg: "Enter Answer",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.SNACKBAR,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.cyan,
                              textColor: Colors.black,
                              fontSize: 16.0,
                            );
                          } else {
                            String question1 = _selected1!, question2 = _selected2!;
                            String answer1 = _answer1.text, answer2 = _answer2.text;

                            box.put("Question1", question1);
                            box.put("Question2", question2);
                            box.put("answer1", answer1);
                            box.put("answer2", answer2);
                            Get.back();
                            _answer1.clear();
                            _answer2.clear();
                            // _selected1="";
                            // _selected2="";
                          }
                        },
                        text: "Verify",
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        shape: GFButtonShape.pills,
                        color: Colors.cyan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}*/
