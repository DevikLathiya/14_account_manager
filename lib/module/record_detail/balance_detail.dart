import 'dart:io';

import 'package:account_manager/core/app_theme.dart';
import 'package:account_manager/core/app_text_field.dart';
import 'package:account_manager/model/account_model.dart';
import 'package:account_manager/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../service/sync_controller.dart';
import 'balance_detail_controller.dart';

class BalanceDetailScreen extends StatefulWidget {
  final AccountModel person;

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
    return GetX<BalanceController>(
      init: BalanceController(),
      initState: (state) => state.controller?.getTransaction(widget.person.id),
      builder: (controller) {
        controller.credit.value;
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: MyColors.primaryColor,
            title: Text(
              widget.person.name,
              style: TextStyle(fontFamily: Fonts.poppinsMedium, color: MyColors.white, fontSize: 18),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: MyColors.white),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  controller.group.value = "Credit";
                  transactionDialog(0, "", "", "", "", controller, context);
                },
                icon: Icon(Icons.add_circle, color: MyColors.white),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Credit/Debit",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 12, color: Colors.grey.shade600, letterSpacing: 0.5),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Particular",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 12, color: Colors.grey.shade600, letterSpacing: 0.5),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Balance",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 12, color: Colors.grey.shade600, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Obx(() {
                  // 1) Group by date (preserve original insertion order per date)
                  Map<String, List<TransactionModel>> grouped = {};
                  for (var item in controller.trData) {
                    grouped.putIfAbsent(item.date, () => []).add(item);
                  }

                  // 2) Sort dates descending (newest first). Adjust parse if your date format varies.
                  List<String> dates = grouped.keys.toList();
                  DateTime parseDate(String d) {
                    try {
                      final parts = d.split('/');
                      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                    } catch (e) {
                      return DateTime(1970);
                    }
                  }

                  dates.sort((a, b) => parseDate(b).compareTo(parseDate(a)));

                  // 3) Build a flat ordered list in the same order we will render (dates desc, items in grouped[date] order)
                  final List<TransactionModel> ordered = [];
                  for (final d in dates) {
                    ordered.addAll(grouped[d]!);
                  }

                  // 4) Compute running balance forward (oldest → newest)
                  final Map<int, double> balanceMap = {};
                  double curr = 0.0; // opening balance (set from DB if you have one)

                  for (final tx in ordered.reversed) {
                    // reverse because ordered is newest→oldest
                    double credit = tx.credit;
                    double debit = tx.debit;

                    curr = curr + credit - debit;
                    balanceMap[tx.id] = curr;
                    controller.credit.value;
                  }

                  return RefreshIndicator(
                    color: MyColors.primaryColor,
                    backgroundColor: Colors.white,
                    onRefresh: () async => await controller.getTransaction(widget.person.id),
                    child: ListView.builder(
                      itemCount: dates.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, dateIndex) {
                        final date = dates[dateIndex];
                        final items = grouped[date]!;

                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 18, bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Text(
                                date.replaceAll('/', '-'),
                                style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 10, color: Colors.grey.shade700),
                              ),
                            ),

                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F3F4)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  children: [
                                    ...items.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;

                                      final bool isCredit = item.credit != 0.0;
                                      final double amountDouble = isCredit ? item.credit : item.debit;
                                      final amountStr = (amountDouble % 1 == 0) ? amountDouble.toStringAsFixed(0) : amountDouble.toStringAsFixed(2);

                                      final tColor = isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

                                      final bal = balanceMap[item.id] ?? 0.0;
                                      final balStr = (bal % 1 == 0) ? bal.toStringAsFixed(0) : bal.toStringAsFixed(2);

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (index > 0) Divider(height: 1, color: Colors.grey.shade100),
                                          InkWell(
                                            onTap: () => editDeleteDialog(context, isCredit, amountStr, item, controller),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                              color: Colors.white,
                                              child: Row(
                                                children: [
                                                  // Amount Column
                                                  Expanded(
                                                    child: Center(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                        decoration: BoxDecoration(
                                                          color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          "${isCredit ? '+' : '-'} ₹$amountStr",
                                                          style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 13, color: tColor),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Particular Column
                                                  Expanded(
                                                    flex: 2,
                                                    child: Center(
                                                      child: Text(
                                                        item.detail,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 13, color: MyColors.primaryColor),
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ),

                                                  // Running Balance Column
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        "₹$balStr",
                                                        style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 14, color: MyColors.primaryColor),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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

              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: EdgeInsets.fromLTRB(20, 0, 20, Platform.isAndroid ? 10 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Credit",
                              style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 11, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 4),
                            Obx(() {
                              controller.credit.value;
                              final double valDouble = (controller.credit.value == "null")
                                  ? 0.0
                                  : (temp)
                                  ? (double.tryParse("${controller.totalTrans[0]['sum_cre']}") ?? 0.0)
                                  : widget.person.credit;
                              final valStr = (valDouble % 1 == 0) ? valDouble.toStringAsFixed(0) : valDouble.toStringAsFixed(2);
                              return Text(
                                "₹$valStr",
                                style: const TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 15, color: Color(0xFF2E7D32)),
                              );
                            }),
                          ],
                        ),
                      ),
                      Container(height: 30, width: 1, color: Colors.grey.shade200),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Debit",
                              style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 11, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 4),
                            Obx(() {
                              controller.credit.value;
                              final double valDouble = (controller.debits.value == "null")
                                  ? 0.0
                                  : (temp)
                                  ? (double.tryParse("${controller.totalTrans[0]['sum_deb']}") ?? 0.0)
                                  : widget.person.debit;
                              final valStr = (valDouble % 1 == 0) ? valDouble.toStringAsFixed(0) : valDouble.toStringAsFixed(2);
                              return Text(
                                "₹$valStr",
                                style: const TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 15, color: Color(0xFFC62828)),
                              );
                            }),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Net Balance",
                                style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                              const SizedBox(height: 2),
                              Obx(() {
                                controller.credit.value;
                                final double valDouble = (temp) ? (double.tryParse(controller.totalBalance.value) ?? 0.0) : widget.person.balance;
                                final valStr = (valDouble % 1 == 0) ? valDouble.toStringAsFixed(0) : valDouble.toStringAsFixed(2);
                                return Text(
                                  "₹$valStr",
                                  style: const TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 16, color: Colors.white),
                                );
                              }),
                            ],
                          ),
                        ),
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

  void editDeleteDialog(BuildContext context, bool isCredit, String amountStr, TransactionModel item, BalanceController controller) {
    showDialog(
      context: context,
      builder: (cont) {
        Widget buildDetailRow(String label, String value, IconData icon) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
    
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative header indicating status
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isCredit ? "Credit Transaction" : "Debit Transaction",
                      style: TextStyle(
                        fontFamily: Fonts.poppinsSemiBold,
                        fontSize: 13,
                        color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${isCredit ? '+' : '-'} ₹$amountStr",
                      style: TextStyle(
                        fontFamily: Fonts.poppinsSemiBold,
                        fontSize: 28,
                        color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
    
              // Transaction Information details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDetailRow("Date", item.date.replaceAll('/', '-'), Icons.calendar_month_rounded),
                    const SizedBox(height: 16),
                    buildDetailRow("Particulars / Description", item.detail, Icons.description_outlined),
                    const SizedBox(height: 28),
    
                    // Edit & Delete Action Buttons
                    Row(
                      children: [
                        // Delete Button
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              side: const BorderSide(color: Color(0xFFC62828)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Get.back();
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    clipBehavior: Clip.antiAlias,
                                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Warning/Delete header
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          width: double.infinity,
                                          color: const Color(0xFFFFEBEE),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Color(0xFFC62828),
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                "Delete Transaction?",
                                                style: TextStyle(
                                                  fontFamily: Fonts.poppinsSemiBold,
                                                  fontSize: 18,
                                                  color: Color(0xFFC62828),
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Dialog Content
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                "Are you sure you want to delete this transaction permanently? This action cannot be undone.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: Fonts.poppinsRegular,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  height: 1.5,
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
                                                      onPressed: () => Get.back(),
                                                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFFC62828),
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        elevation: 0,
                                                      ),
                                                      onPressed: () async {
                                                        temp = true;
                                                        await controller.transDelete(orderId: item.id, acId: widget.person.id);
                                                        Get.back();
                                                      },
                                                      child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
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
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 18),
                                const SizedBox(width: 6),
                                const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
    
                        // Edit Button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              Get.back();
                              if (item.credit > 0.0) {
                                controller.group.value = "Credit";
                                _amount.text = "${item.credit}";
                              } else {
                                controller.group.value = "Debit";
                                _amount.text = "${item.debit}";
                              }
                              transactionDialog(item.id, item.date, item.detail, item.credit, item.debit, controller, context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 6),
                                const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void transactionDialog(int tid, String date, name, credit, debit, BalanceController controller, context) {
    showDialog(
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Dialog Title Bar
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
                    (date != '') ? "Edit Transaction" : "Add Transaction",
                    style: TextStyle(
                      fontFamily: Fonts.poppinsSemiBold,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Dialog Content Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Obx(
                    () => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Selector Tile
                        GestureDetector(
                          onTap: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            controller.datePickerBox(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, color: MyColors.primaryColor, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  "Date :",
                                  style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 14, color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  controller.today.value,
                                  style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 14, color: Colors.black87),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Transaction Type Selector (Credit/Debit Segmented Style)
                        Text(
                          "Transaction Type",
                          style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Credit Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () => controller.group.value = "Credit",
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: controller.group.value == "Credit"
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: controller.group.value == "Credit"
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: controller.group.value == "Credit"
                                            ? const Color(0xFF2E7D32)
                                            : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Credit (+)",
                                        style: TextStyle(
                                          fontFamily: Fonts.poppinsMedium,
                                          fontSize: 14,
                                          color: controller.group.value == "Credit"
                                              ? const Color(0xFF2E7D32)
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Debit Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () => controller.group.value = "Debit",
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: controller.group.value == "Debit"
                                        ? const Color(0xFFFFEBEE)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: controller.group.value == "Debit"
                                          ? const Color(0xFFC62828)
                                          : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: controller.group.value == "Debit"
                                            ? const Color(0xFFC62828)
                                            : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Debit (-)",
                                        style: TextStyle(
                                          fontFamily: Fonts.poppinsMedium,
                                          fontSize: 14,
                                          color: controller.group.value == "Debit"
                                              ? const Color(0xFFC62828)
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Amount Field
                        AppTextField(
                          controller: _amount,
                          labelText: "Amount",
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [LengthLimitingTextInputFormatter(6), FilteringTextInputFormatter.digitsOnly],
                        ),
                        const SizedBox(height: 16),

                        // Particular Field
                        AppTextField(
                          controller: _particular,
                          labelText: "Particular (Remarks)",
                          prefixIcon: Icons.description_outlined,
                        ),
                        const SizedBox(height: 24),

                        // Buttons
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
                                  controller.group.value = "";
                                  _particular.clear();
                                  _amount.clear();
                                  controller.myDate();
                                  Get.back();
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
                                  } else {
                                    await controller.insertBalanceData(widget.person.id, detail, credit, debit);
                                  }
                                  await controller.getTransaction(widget.person.id);
                                  if (Get.isRegistered<SyncController>()) {
                                    Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
                                  }
                                  _particular.clear();
                                  controller.group.value = "";
                                  Get.back();
                                },
                                child: Text((date != "") ? "Update" : "Add", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
