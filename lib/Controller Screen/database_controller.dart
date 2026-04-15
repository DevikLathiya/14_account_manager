import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'dart:math';
import '../splash_screen.dart';
import 'sync_controller.dart';

class DatabaseController extends GetxController {
  RxInt index = 0.obs;
  Box box = Hive.box("Account");

  ScrollController scrollController = ScrollController();

  RxList<Map<String, dynamic>> mainTrans = RxList<Map<String, dynamic>>([]);
  RxString mainBalance = ''.obs, cr = ''.obs, de = ''.obs;
  RxList<Map> getData = [{}].obs;

  Future<void> insertData(String name) async {
    int ts = DateTime.now().millisecondsSinceEpoch;
    int rndId = Random().nextInt(9000000) + 100000;
    String insert = "insert into Account values($rndId,'$name','0','0','0', 0, 0, $ts)";
    await SplashScreen.database!.rawInsert(insert);
    print("inserted");
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    }
  }

  Future<void> selectData() async {
    String select = "select * from Account where is_deleted=0";
    getData.value = await SplashScreen.database!.rawQuery(select);
    await totalStatement();

    print(":::::::::: getData ::::::: $getData");
  }

  Future<void> updateData(String name, int id) async {
    int ts = DateTime.now().millisecondsSinceEpoch;
    String update = "update Account set name='$name', is_synced=0, updated_at=$ts where id='$id'";
    await SplashScreen.database!.rawUpdate(update);
    await selectData();
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    }
  }

  Future<void> deleteData(int id) async {
    int ts = DateTime.now().millisecondsSinceEpoch;
    // Delete account
    String deleteAccount = "UPDATE Account SET is_deleted=1, is_synced=0, updated_at=$ts WHERE id=$id";
    await SplashScreen.database!.rawUpdate(deleteAccount);

    // Delete related transactions
    String deleteTransactions = "UPDATE MyTransaction SET is_deleted=1, is_synced=0, updated_at=$ts WHERE AcId=$id";
    await SplashScreen.database!.rawUpdate(deleteTransactions);

    // Refresh data
    await selectData();
    // await totalStatement();

    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    }
  }

  Future<void> totalStatement() async {
    String main = "SELECT SUM(credit) as mainCredit , SUM(debit) as mainDebit FROM MyTransaction WHERE is_deleted=0";
    mainTrans.value = await SplashScreen.database!.rawQuery(main);

    cr.value = mainTrans[0]['mainCredit']?.toString() ?? "0";
    de.value = mainTrans[0]['mainDebit']?.toString() ?? "0";

    // ✅ safely parse as double
    final crVal = double.tryParse(cr.value) ?? 0.0;
    final deVal = double.tryParse(de.value) ?? 0.0;

    mainBalance.value = (crVal - deVal).toStringAsFixed(2);
    print("total : ${mainBalance.value}");
  }
}
