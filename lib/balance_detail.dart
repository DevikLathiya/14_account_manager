import 'package:account_manager/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/shape/gf_button_shape.dart';
import 'package:getwidget/types/gf_button_type.dart';
import 'Controller Screen/GetXController.dart';

class BalanceDetailScreen extends StatefulWidget {
  final Map<dynamic, dynamic> person;

  const BalanceDetailScreen(this.person, {super.key});

  @override
  State<BalanceDetailScreen> createState() => _BalanceDetailScreenState();
}

class _BalanceDetailScreenState extends State<BalanceDetailScreen> {
  bool temp = false;

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _particular = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return GetX<BalanceController>(
      init: BalanceController(),
      initState: (state) => state.controller?.getTransaction(widget.person['id']),
      builder: (controller) {
        print("totalTrans ${controller.totalTrans}");
        print("widget ${widget.person}");
        print("controller.totalTrans[0]['sum_cre'] ${controller.totalTrans[0]['sum_cre']}");
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text("${widget.person["name"]}", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
            leading: IconButton(
              onPressed: () {
                Get.back();
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
              },
              icon: Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  controller.group.value = "Credit";
                  transactionDialog(0, "", "", "", "", controller, context);
                },
                icon: Icon(Icons.add_circle),
              ),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(0, 1, 0, 3),
                padding: EdgeInsets.all(8),
                color: Colors.grey.shade300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Center(
                        child: Text("Credit/Debit", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text("Particular", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text("Balance", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 7,
                child: Obx(() {
                  // 1) Group by date (preserve original insertion order per date)
                  Map<String, List<Map<String, dynamic>>> grouped = {};
                  for (var item in controller.trData) {
                    final date = (item['date'] ?? '').toString();
                    grouped.putIfAbsent(date, () => []).add(Map<String, dynamic>.from(item));
                  }

                  // 2) Sort dates descending (newest first). Adjust parse if your date format varies.
                  List<String> dates = grouped.keys.toList();
                  DateTime _parseDate(String d) {
                    try {
                      final parts = d.split('/');
                      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                    } catch (e) {
                      return DateTime(1970);
                    }
                  }

                  dates.sort((a, b) => _parseDate(b).compareTo(_parseDate(a)));

                  // 3) Build a flat ordered list in the same order we will render (dates desc, items in grouped[date] order)
                  final List<Map<String, dynamic>> ordered = [];
                  for (final d in dates) {
                    ordered.addAll(grouped[d]!);
                  }

                  // 4) Compute running balance forward (oldest → newest)
                  final Map<dynamic, double> balanceMap = {};
                  double curr = 0.0; // opening balance (set from DB if you have one)

                  for (final tx in ordered.reversed) {
                    // reverse because ordered is newest→oldest
                    double credit = 0.0;
                    double debit = 0.0;

                    if (tx['credit'] != null) {
                      if (tx['credit'] is num)
                        credit = (tx['credit'] as num).toDouble();
                      else
                        credit = double.tryParse(tx['credit'].toString()) ?? 0.0;
                    }
                    if (tx['debit'] != null) {
                      if (tx['debit'] is num)
                        debit = (tx['debit'] as num).toDouble();
                      else
                        debit = double.tryParse(tx['debit'].toString()) ?? 0.0;
                    }

                    curr = curr + credit - debit;
                    balanceMap[tx['id']] = curr;
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.getTransaction(widget.person['id']),
                    child: ListView.builder(
                      itemCount: dates.length,
                      itemBuilder: (context, dateIndex) {
                        final date = dates[dateIndex];
                        final items = grouped[date]!;

                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 4),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                              child: Text(date.replaceAll('/', '-'), style: Theme.of(context).poppinsBold.copyWith(fontSize: 10)),
                            ),

                            Container(
                              margin: EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Column(
                                  children: [
                                    ...items.map((item) {
                                      final tColor = (item['credit'] != null && (double.tryParse(item['credit'].toString()) ?? 0.0) != 0)
                                          ? Colors.green.shade700
                                          : Colors.red;
                                      final amount = ((double.tryParse(item['credit'].toString()) ?? 0.0) != 0.0) ? item['credit'] : item['debit'];
                                      final bal = balanceMap[item['id']] ?? 0.0;
                                      final balStr = (bal % 1 == 0) ? bal.toStringAsFixed(0) : bal.toStringAsFixed(2);

                                      return InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (cont) {
                                              return AlertDialog(
                                                title: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                  children: [
                                                    GFButton(
                                                      onPressed: () async {
                                                        Get.back();
                                                        if ((double.tryParse(item['credit'].toString()) ?? 0.0) > 0) {
                                                          controller.group.value = "Credit";
                                                          _amount.text = "${item['credit']}";
                                                        } else {
                                                          controller.group.value = "Debit";
                                                          _amount.text = "${item['debit']}";
                                                        }
                                                        transactionDialog(
                                                          item['id'],
                                                          item['date'],
                                                          item['detail'],
                                                          item['credit'],
                                                          item['debit'],
                                                          controller,
                                                          context,
                                                        );
                                                      },
                                                      text: "Edit",
                                                      textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                                                      type: GFButtonType.outline,
                                                      shape: GFButtonShape.pills,
                                                      color: MyColors.primaryColor,
                                                    ),
                                                    GFButton(
                                                      onPressed: () {
                                                        Get.back();
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              title: Text("Are Want To Delete?", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18)),
                                                              actions: [
                                                                GFButton(
                                                                  onPressed: () => Get.back(),
                                                                  text: "cancel",
                                                                  textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                                                                  type: GFButtonType.outline,
                                                                  shape: GFButtonShape.pills,
                                                                  color: MyColors.primaryColor,
                                                                ),
                                                                GFButton(
                                                                  onPressed: () async {
                                                                    temp = true;
                                                                    await controller.transDelete(orderId: item['id'], acId: widget.person['id']);
                                                                    Get.back();
                                                                  },
                                                                  text: "Delete",
                                                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                                                  shape: GFButtonShape.pills,
                                                                  color: MyColors.primaryColor,
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                      text: "Delete",
                                                      textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                                                      type: GFButtonType.outline,
                                                      shape: GFButtonShape.pills,
                                                      color: MyColors.primaryColor,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          color: Colors.grey.shade50,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Center(
                                                  child: Text("$amount", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 15, color: tColor)),
                                                ),
                                              ),

                                              // Detail column
                                              Expanded(
                                                flex: 2,
                                                child: Center(
                                                  child: Text(
                                                    "${item['detail']}",
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).poppinsRegular.copyWith(fontSize: 12),
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),

                                              // Running balance column
                                              Expanded(
                                                child: Center(
                                                  child: Text(balStr, style: Theme.of(context).poppinsMedium.copyWith(fontSize: 15, color: tColor)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }),
              ),

              /*Expanded(
                flex: 7,
                child: ListView.builder(
                  itemCount: controller.trData.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    var debitlength = (controller.trData[index]['debit'].bitLength >= 20);
                    var creditlength = (controller.trData[index]['credit'].bitLength >= 20);
                    var namelength = (controller.trData[index]['detail'].toString().length >= 7);
                    var mycolor = controller.trData[index]['credit'] == 0 ? Colors.red : Colors.green.shade500;

                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  GFButton(
                                    onPressed: () {
                                      Get.back();
                                      add_upTransaction(
                                        controller.trData[index]['id'],
                                        controller.trData[index]['date'],
                                        controller.trData[index]['detail'],
                                        controller.trData[index]['credit'],
                                        controller.trData[index]['debit'],
                                        controller,
                                      );
                                    },
                                    text: "Edit",
                                    textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 15),
                                    type: GFButtonType.outline,
                                    shape: GFButtonShape.pills,
                                    color: Colors.cyan,
                                  ),
                                  GFButton(
                                    onPressed: () {
                                      Get.back();
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text("Are Want To Delete?"),
                                            actions: [
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
                                                  controller.trans_delete(controller.trData[index]['id']);
                                                  Get.back();
                                                },
                                                text: "Delete",
                                                textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                                shape: GFButtonShape.pills,
                                                color: Colors.cyan,
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    text: "Delete",
                                    textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 15),
                                    type: GFButtonType.outline,
                                    shape: GFButtonShape.pills,
                                    color: Colors.cyan,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 2, 0, 0),
                        padding: EdgeInsets.all(5),
                        color: (index % 2 == 0) ? Colors.grey.shade50 : Colors.grey.shade200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  "${controller.trData[index]['date']}",
                                  style: TextStyle(color: mycolor, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),

                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  "${controller.trData[index]['detail']}",
                                  style: TextStyle(fontSize: namelength ? 13 : 16, color: mycolor, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  "${controller.trData[index]['credit']}",
                                  style: TextStyle(fontSize: creditlength ? 13 : 16, color: mycolor, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),

                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  "${controller.trData[index]['debit']}",
                                  style: TextStyle(fontSize: debitlength ? 13 : 16, color: mycolor, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),*/
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: width * 0.30,
                    height: 60,
                    padding: EdgeInsets.symmetric(vertical: 4),
                    margin: EdgeInsets.fromLTRB(7, 0, 0, 3),
                    decoration: BoxDecoration(
                      color: MyColors.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Credit", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 16)),
                        Obx(
                          () => Text(
                            (controller.credit.value == "null")
                                ? "₹ 00"
                                : (temp)
                                ? "₹ ${controller.totalTrans[0]['sum_cre']  ?? "0.0"}"
                                : "₹ ${widget.person['credit']}",
                            style: Theme.of(context).poppinsMedium.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: width * 0.30,
                    height: 60,
                    padding: EdgeInsets.symmetric(vertical: 4),
                    margin: EdgeInsets.only(bottom: 3),
                    color: MyColors.primaryColor.withValues(alpha: 0.3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Debit", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 16)),
                        Obx(
                          () => Text(
                            (controller.debits.value == "null")
                                ? "₹ 00"
                                : (temp)
                                ? "₹ ${controller.totalTrans[0]['sum_deb'] ?? "0.0"}"
                                : "₹ ${widget.person['debit']}",
                            style: Theme.of(context).poppinsMedium.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: width * 0.30,
                    height: 60,
                    padding: EdgeInsets.symmetric(vertical: 4),
                    margin: const EdgeInsets.fromLTRB(0, 0, 7, 3),
                    decoration: BoxDecoration(
                      color: MyColors.primaryColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text("Balance", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 16, color: Colors.white)),
                        FittedBox(
                          child: Text(
                            (temp) ? "₹ ${controller.totalBalance.value}" : "₹ ${widget.person['balance']}",
                            style: Theme.of(context).poppinsMedium.copyWith(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void transactionDialog(int tid, String date, name, credit, debit, BalanceController controller, context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        controller.myDate();
        if (date != '') {
          controller.today.value = date;
          _particular.text = name;
          if ((double.tryParse(credit.toString()) ?? 0.0) > 0) {
            controller.group.value = "Credit";
            _amount.text = "$credit";
          } else {
            controller.group.value = "Debit";
            _amount.text = "$debit";
          }
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 50,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  (date != '') ? "Update Transaction" : "Add Transaction",
                  style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  controller.datePickerBox(context);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(" Date :", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                    SizedBox(width: 10),
                    Obx(() => Text(controller.today.value, style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14))),
                    SizedBox(width: 6),
                    Icon(Icons.calendar_month_rounded, color: MyColors.primaryColor, size: 18),
                  ],
                ).paddingSymmetric(vertical: 20),
              ),
              Text("Transcation Type : ", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 12)),
              Row(
                children: [
                  Text("Credit(+)", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                  Obx(
                    () => Radio(
                      value: "Credit",
                      activeColor: MyColors.primaryColor,
                      groupValue: controller.group.value,
                      onChanged: (value) {
                        controller.group.value = value.toString();
                      },
                    ),
                  ),
                  Text("Debit(-)", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                  Obx(
                    () => Radio(
                      value: "Debit",
                      activeColor: MyColors.primaryColor,
                      groupValue: controller.group.value,
                      onChanged: (value) {
                        controller.group.value = value.toString();
                      },
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.phone,
                inputFormatters: [LengthLimitingTextInputFormatter(4), FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(label: Text("Amount", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14))),
              ),
              TextField(
                controller: _particular,
                decoration: InputDecoration(label: Text("Particular", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14))),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GFButton(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 4),
                    onPressed: () {
                      controller.group.value = "";
                      _particular.clear();
                      _amount.clear();
                      controller.myDate();
                      Get.back();
                    },
                    text: "cancel",
                    textStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.primaryColor, fontSize: 15),
                    type: GFButtonType.outline,
                    shape: GFButtonShape.pills,
                    color: MyColors.primaryColor,
                  ),
                  GFButton(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 4),
                    onPressed: () async {
                      temp = true;
                      String credit = "0", debit = "0", detail = _particular.text;
                      if (controller.group.value == "Credit") {
                        credit = _amount.text;
                        _amount.clear();
                      } else {
                        debit = _amount.text;
                        _amount.clear();
                      }

                      if (date != '') {
                        await controller.transUpdate(tid, date, detail, credit, debit);
                        await controller.getTransaction(widget.person['id']);
                      } else {
                        controller.insertBalanceData(widget.person['id'], detail, credit, debit);
                      }
                      _particular.clear();
                      controller.group.value = "";
                      Get.back();
                    },
                    text: (date != "") ? "Update" : "ADD",
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
}
