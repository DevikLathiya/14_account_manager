import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../second_page.dart';

class MyController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxInt index = 0.obs;
  RxInt digit = 0.obs;
  RxString code = ''.obs;
  RxString password = ''.obs;
  Box box = Hive.box("Account");

  RxInt selectedRoomTypeIndex = (-1).obs;
  RxnString? roomTypeError = RxnString(null);

  ScrollController scrollController = ScrollController();

  // ✅ Call this when submitting the form
  bool validateRoomTypeSelection() {
    if (selectedRoomTypeIndex.value == -1) {
      roomTypeError?.value = "Please select your room type";
      return false;
    }
    roomTypeError?.value = null;
    return true;
  }

  addDigit(int digit) {
    if (code.value.length > 3) {
      return;
    }
    code.value = code + digit.toString();
    selectedIndex.value = code.value.length;
  }

  backspace() {
    if (code.value.isEmpty) {
      return;
    }
    code.value = code.value.substring(0, code.value.length - 1);
    selectedIndex.value = code.value.length;
  }

  getPassword() {
    password.value = box.get("password");
    return password;
  }

  RxString selected1 = ''.obs;

  dropdown(value) {
    selected1.value = value;
  }

  //----------------Database----------------------

  RxList<Map> getData = [{}].obs;

  Future<void> insertData(String name) async {
    String insert = "insert into Account values(null,'$name','0','0','0')";
    await SecondPage.database!
        .rawInsert(insert)
        .then(
          (value) => (value) {
            print("value $value");
          },
        );
    print("inserted");
  }

  Future<void> selectData() async {
    String select = "select * from Account";
    getData.value = await SecondPage.database!.rawQuery(select);
    await totalStatement();
  }

  Future<void> updateData(String name, int id) async {
    String update = "update Account set name='$name' where id='$id'";
    await SecondPage.database!.rawUpdate(update);
    await selectData();
  }

  Future<void> deleteData(int id) async {
    // Delete account
    String deleteAccount = "DELETE FROM Account WHERE id=$id";
    await SecondPage.database!.rawDelete(deleteAccount);

    // Delete related transactions
    String deleteTransactions = "DELETE FROM MyTransaction WHERE AcId=$id";
    await SecondPage.database!.rawDelete(deleteTransactions);

    // Refresh data
    await selectData();
    // await totalStatement();
  }

  //------------------------balance Page---------------------

  RxList<Map<String, dynamic>> mainTrans = RxList<Map<String, dynamic>>([]);
  RxString mainBalance = ''.obs, cr = ''.obs, de = ''.obs;

  Future<void> totalStatement() async {
    String main = "SELECT SUM(credit) as mainCredit , SUM(debit) as mainDebit FROM MyTransaction";
    mainTrans.value = await SecondPage.database!.rawQuery(main);

    cr.value = mainTrans[0]['mainCredit']?.toString() ?? "0";
    de.value = mainTrans[0]['mainDebit']?.toString() ?? "0";


    // ✅ safely parse as double
    final crVal = double.tryParse(cr.value) ?? 0.0;
    final deVal = double.tryParse(de.value) ?? 0.0;

    mainBalance.value = (crVal - deVal).toStringAsFixed(2);
    print("total : ${mainBalance.value}");
  }
}

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
    String insert = "insert into MyTransaction values(null,'${today.value}','$id','$detail',${newCredit.toString()},${newDebit.toString()})";
    await SecondPage.database!.rawInsert(insert);

    getTransaction(id);
  }

  Future<void> getTransaction(int id) async {
    String select = "select * from MyTransaction where AcId='$id' order by id desc";
    trData.value = await SecondPage.database!.rawQuery(select);

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
    String update = "update MyTransaction set date='$dd',detail='$name',credit='$newCredit',debit='$newDebit' where id='$tid'";
    await SecondPage.database!.rawUpdate(update);
  }

  Future<void> transDelete({required int orderId, required int acId}) async {
    String delete = "delete from MyTransaction where id = '$orderId'";
    await SecondPage.database!.rawDelete(delete);
    getTransaction(acId);
  }

  Future<void> totalCreDeb(int id) async {
    totalBalance.value = "";
    String creditQuery = "SELECT SUM(credit) as sum_cre , SUM(debit) as sum_deb FROM MyTransaction where AcId =$id";
    totalTrans.value = await SecondPage.database!.rawQuery(creditQuery);

    credit.value = totalTrans[0]['sum_cre']?.toString() ?? "0.0";
    debits.value = totalTrans[0]['sum_deb']?.toString() ?? "0.0";

    final crVal = double.tryParse(credit.value) ?? 0.0;
    final deVal = double.tryParse(debits.value) ?? 0.0;

    totalBalance.value = (crVal - deVal).toStringAsFixed(2);

    String update = "update Account set credit='${credit.value}',debit='${debits.value}', balance='${totalBalance.value}' where id=$id";
    await SecondPage.database!.rawUpdate(update);
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
