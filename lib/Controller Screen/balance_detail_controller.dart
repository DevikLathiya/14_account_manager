import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../splash_screen.dart';
import 'sync_controller.dart';

class BalanceController extends GetxController {
  RxString group = "".obs;

  DateTime? pickDate, todayDate = DateTime.now();
  RxString today = ''.obs;

  RxList<Map<String, dynamic>> totalTrans = RxList<Map<String, dynamic>>([]);
  RxString debits = ''.obs;
  RxString credit = ''.obs;
  RxString totalBalance = ''.obs;

  RxList<Map<String, dynamic>> trData = RxList<Map<String, dynamic>>([]);

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
    trData.value = await SplashScreen.database!.rawQuery(select);

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
    today.value = "${todayDate!.day}/${todayDate!.month}/${todayDate!.year}";
    pickDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.utc(1980), lastDate: DateTime.now());

    if (pickDate == null) {
      today.value = "${todayDate!.day}/${todayDate!.month}/${todayDate!.year}";
    } else {
      today.value = "${pickDate!.day}/${pickDate!.month}/${pickDate!.year}";
    }
  }
}