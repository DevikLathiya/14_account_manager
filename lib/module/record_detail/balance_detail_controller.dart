import 'package:account_manager/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../auth_flow/splash_screen.dart';
import '../service/sync_controller.dart';

import '../../core/app_theme.dart';

class BalanceController extends GetxController {
  RxString group = "".obs;

  DateTime? pickDate, todayDate = DateTime.now();
  RxString today = ''.obs;

  RxList<Map<String, dynamic>> totalTrans = RxList<Map<String, dynamic>>([]);
  RxString debits = ''.obs;
  RxString credit = ''.obs;
  RxString totalBalance = ''.obs;

  RxList<TransactionModel> trData = RxList<TransactionModel>([]);

  myDate() => today.value = "${todayDate!.day}/${todayDate!.month}/${todayDate!.year}";

  Future<void> insertBalanceData(id, String detail, String credit, String debit) async {
    var newCredit = double.tryParse(credit) ?? 0.0;
    var newDebit = double.tryParse(debit) ?? 0.0;
    int ts = DateTime.now().millisecondsSinceEpoch;
    int rndId = Random().nextInt(9000000) + 100000;
    String insert = "insert into MyTransaction values($rndId,'${today.value}','$id','$detail',${newCredit.toString()},${newDebit.toString()}, 0, 0, $ts)";
    await SplashScreen.database!.rawInsert(insert);

    // getTransaction(id);
    // if (Get.isRegistered<SyncController>()) {
    //   Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    // }
  }

  Future<void> getTransaction(int id) async {
    String select = "select * from MyTransaction where AcId='$id' and is_deleted=0 order by updated_at desc";
    final List<Map<String, dynamic>> maps = await SplashScreen.database!.rawQuery(select);
    trData.value = maps.map((map) => TransactionModel.fromMap(map)).toList();

    // if (trData.isNotEmpty) {
    totalCreDeb(id);
    // }
  }

  Future<void> transUpdate(int tid, String date, name, String credit, String debit) async {
    String dd = date;
    if (today.value != "") {
      dd = today.value;
    }
    var newCredit = double.tryParse(credit) ?? 0.0;
    var newDebit = double.tryParse(debit) ?? 0.0;
    int ts = DateTime.now().millisecondsSinceEpoch;
    String update = "update MyTransaction set date='$dd',detail='$name',credit='$newCredit',debit='$newDebit', is_synced=0, updated_at=$ts where id='$tid'";
    await SplashScreen.database!.rawUpdate(update);
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    }
  }

  Future<void> transDelete({required int orderId, required int acId}) async {
    int ts = DateTime.now().millisecondsSinceEpoch;
    String delete = "update MyTransaction set is_deleted=1, is_synced=0, updated_at=$ts where id = '$orderId'";
    await SplashScreen.database!.rawUpdate(delete);
    getTransaction(acId);
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    }
  }

  Future<void> totalCreDeb(int id) async {
    totalBalance.value = "";
    String creditQuery = "SELECT SUM(credit) as sum_cre , SUM(debit) as sum_deb FROM MyTransaction where AcId =$id and is_deleted=0";
    totalTrans.value = await SplashScreen.database!.rawQuery(creditQuery);

    credit.value = totalTrans[0]['sum_cre']?.toString() ?? "0.0";
    debits.value = totalTrans[0]['sum_deb']?.toString() ?? "0.0";

    final crVal = double.tryParse(credit.value) ?? 0.0;
    final deVal = double.tryParse(debits.value) ?? 0.0;

    totalBalance.value = (crVal - deVal).toStringAsFixed(2);

    int ts = DateTime.now().millisecondsSinceEpoch;
    String update = "update Account set credit='${credit.value}',debit='${debits.value}', balance='${totalBalance.value}', is_synced=0, updated_at=$ts where id=$id";
    await SplashScreen.database!.rawUpdate(update);
    // if (Get.isRegistered<SyncController>()) {
    //   Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    // }
  }

  Future<void> datePickerBox(BuildContext context) async {
    DateTime initial = DateTime.now();
    if (today.value.isNotEmpty) {
      try {
        final parts = today.value.split('/');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }

    pickDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.utc(1980),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: MyColors.primaryColor, onPrimary: Colors.white, onSurface: Colors.black87),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: MyColors.primaryColor)),
          ),
          child: child!,
        );
      },
    );

    if (pickDate != null) {
      today.value = "${pickDate!.day}/${pickDate!.month}/${pickDate!.year}";
    }
  }
}
