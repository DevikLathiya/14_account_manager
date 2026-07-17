import 'package:account_manager/core/app_encryption.dart';
import 'package:account_manager/core/app_snackbar.dart';
import 'package:account_manager/core/app_theme.dart';
import 'package:account_manager/model/account_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../auth_flow/splash_screen.dart';
import 'sync_controller.dart';

class DatabaseController extends GetxController {
  Box box = Hive.box("Account");

  RxList<Map<String, dynamic>> mainTrans = RxList<Map<String, dynamic>>([]);
  RxString mainBalance = ''.obs, cr = ''.obs, de = ''.obs;
  RxList<AccountModel> getData = RxList<AccountModel>([]);

  Future<void> insertData(String name) async {
    int ts = DateTime.now().millisecondsSinceEpoch;
    int rndId = Random().nextInt(9000000) + 100000;
    String insert = "insert into Account values($rndId,'$name','0','0','0', 0, 0, $ts)";
    await SplashScreen.database!.rawInsert(insert);
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().autoSyncEnabled.value ? Get.find<SyncController>().syncNow() : null;
    }
  }

  Future<void> selectData() async {
    String select = "select * from Account where is_deleted=0";
    final List<Map<String, dynamic>> maps = await SplashScreen.database!.rawQuery(select);
    getData.value = maps.map((map) => AccountModel.fromMap(map)).toList();
    await totalStatement();
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

  Future<bool> deleteAllData({bool deleteLocal = true, bool deleteDrive = true}) async {
    if (SplashScreen.database == null) {
      return false;
    }

    if (deleteLocal) {
      await SplashScreen.database!.rawDelete("DELETE FROM MyTransaction");
      await SplashScreen.database!.rawDelete("DELETE FROM Account");
    }

    if (deleteDrive) {
      // Also delete from Google Drive if connected
      if (Get.isRegistered<SyncController>()) {
        final syncCtrl = Get.find<SyncController>();
        if (syncCtrl.currentUser.value != null) {
          await syncCtrl.deleteDriveBackup();
        }
      }
    }

    // Refresh UI
    await selectData();
    await totalStatement();

    return true;
  }

  void promptRestore(BuildContext context, SyncController syncController, DateTime backupDate) {
    String formattedDate = DateFormat.yMMMd().add_jm().format(backupDate.toLocal());
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Backup Found Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              color: const Color(0xFFE8F0FE),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_download_rounded,
                    color: Color(0xFF1967D2),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Backup Found",
                    style: TextStyle(
                      fontFamily: Fonts.poppinsSemiBold,
                      fontSize: 18,
                      color: Color(0xFF1967D2),
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
                  Text.rich(
                    TextSpan(
                      text: "A cloud backup from ",
                      children: [
                        TextSpan(
                          text: formattedDate,
                          style: const TextStyle(
                            fontFamily: Fonts.poppinsSemiBold,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text: " was found. Would you like to restore it? This will replace your current device data.",
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                          onPressed: () => Navigator.pop(ctx),
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
                            Navigator.pop(ctx);
                            showSnackBar(context, 'Processing', 'Restoring...');
                            bool success = await syncController.restoreFromDrive();
                            if (context.mounted) {
                              if (success) {
                                syncController.hasRestoredInSession.value = true;
                                showSnackBar(context, 'Success', 'Restore complete!');
                              } else {
                                showSnackBar(context, 'Error', 'Restore failed.', isError: true);
                              }
                            }
                          },
                          child: const Text("Restore", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> exportData(BuildContext context) async {
    try {
      if (SplashScreen.database == null) {
        showSnackBar(context, 'Error', 'Database not initialized.', isError: true);
        return;
      }

      final accounts = await SplashScreen.database!.rawQuery("SELECT * FROM Account WHERE is_deleted=0");
      final transactions = await SplashScreen.database!.rawQuery("SELECT * FROM MyTransaction WHERE is_deleted=0");

      final Map<String, dynamic> exportMap = {'exported_at': DateTime.now().toIso8601String(), 'accounts': accounts, 'transactions': transactions};

      final String plainJsonStr = jsonEncode(exportMap);
      final String encryptedBase64 = AppEncryption.encrypt(plainJsonStr);

      final Map<String, dynamic> encryptedWrap = {
        'version': 1,
        'encrypted': true,
        'data': encryptedBase64,
      };

      final String finalJsonStr = const JsonEncoder.withIndent('  ').convert(encryptedWrap);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(finalJsonStr));

      final String fileName = 'account_manager_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      final String? resultPath = await FilePicker.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (resultPath == null) return; // User cancelled

      if (context.mounted) {
        showSnackBar(context, 'Success', 'Data exported successfully!');
      }
    } catch (e) {
      print(e);
      if (context.mounted) {
        showSnackBar(context, 'Error', 'Failed to export data: $e', isError: true);
      }
    }
  }

  Future<void> importData(BuildContext context) async {
    try {
      if (SplashScreen.database == null) {
        showSnackBar(context, 'Error', 'Database not initialized.', isError: true);
        return;
      }

      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

      if (result == null) return;

      final String? filePath = result.files.single.path;
      if (filePath == null) return;

      final File file = File(filePath);
      final String jsonStr = await file.readAsString();
      final Map<String, dynamic> importData = jsonDecode(jsonStr);

      List<dynamic> accounts = [];
      List<dynamic> transactions = [];

      if (importData['encrypted'] == true && importData.containsKey('data')) {
        final String decryptedStr = AppEncryption.decrypt(importData['data']);
        final Map<String, dynamic> decryptedMap = jsonDecode(decryptedStr);
        accounts = decryptedMap['accounts'] ?? [];
        transactions = decryptedMap['transactions'] ?? [];
      } else {
        // Legacy unencrypted fallback
        accounts = importData['accounts'] ?? [];
        transactions = importData['transactions'] ?? [];
      }

      if (accounts.isEmpty && transactions.isEmpty) {
        if (context.mounted) {
          showSnackBar(context, 'Notice', 'No data found in the file.');
        }
        return;
      }

      if (!context.mounted) return;

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Import Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: double.infinity,
                color: const Color(0xFFE8F0FE),
                child: Column(
                  children: [
                    const Icon(
                      Icons.file_download_rounded,
                      color: Color(0xFF1967D2),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Import Data",
                      style: TextStyle(
                        fontFamily: Fonts.poppinsSemiBold,
                        fontSize: 18,
                        color: Color(0xFF1967D2),
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
                    Text.rich(
                      TextSpan(
                        text: "Found ",
                        children: [
                          TextSpan(
                            text: "${accounts.length} accounts",
                            style: const TextStyle(
                              fontFamily: Fonts.poppinsSemiBold,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "${transactions.length} transactions",
                            style: const TextStyle(
                              fontFamily: Fonts.poppinsSemiBold,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const TextSpan(
                            text: ".\n\nThis will merge the imported data with your current device data (matching IDs will be updated). Continue?",
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                            onPressed: () => Navigator.pop(ctx, false),
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
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Import", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true) return;

      await SplashScreen.database!.transaction((txn) async {
        for (var acc in accounts) {
          await txn.rawInsert("INSERT OR REPLACE INTO Account (id, name, credit, debit, balance, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [
            acc['id'],
            acc['name'],
            acc['credit'],
            acc['debit'],
            acc['balance'],
            acc['is_synced'] ?? 0,
            acc['is_deleted'] ?? 0,
            acc['updated_at'] ?? 0,
          ]);
        }
        for (var tr in transactions) {
          await txn.rawInsert(
            "INSERT OR REPLACE INTO MyTransaction (id, date, AcId, detail, credit, debit, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [tr['id'], tr['date'], tr['AcId'], tr['detail'], tr['credit'], tr['debit'], tr['is_synced'] ?? 0, tr['is_deleted'] ?? 0, tr['updated_at'] ?? 0],
          );
        }
      });

      await selectData();
      await totalStatement();

      if (Get.isRegistered<SyncController>()) {
        final syncCtrl = Get.find<SyncController>();
        if (syncCtrl.currentUser.value != null) {
          await syncCtrl.backupToDrive();
        }
      }

      if (context.mounted) {
        showSnackBar(context, 'Success', 'Data imported successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Error', 'Failed to import data: $e', isError: true);
      }
    }
  }

  void promptDeleteAllData(BuildContext context) {
    bool deleteLocal = true;
    bool deleteDrive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
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
                        Icons.delete_forever_rounded,
                        color: Color(0xFFC62828),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Delete Data",
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
                        "Select the sources you wish to permanently delete. This action cannot be undone.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Fonts.poppinsRegular,
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Delete Local Switch
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Delete Local Database",
                          style: TextStyle(
                            fontFamily: Fonts.poppinsMedium,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: const Text(
                          "Removes all records from this device",
                          style: TextStyle(
                            fontFamily: Fonts.poppinsRegular,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 0.8,
                          alignment: Alignment.centerRight,
                          child: Switch(
                            activeThumbColor: const Color(0xFFC62828),
                            inactiveTrackColor: Colors.grey.shade200,
                            value: deleteLocal,
                            onChanged: (val) {
                              setState(() {
                                deleteLocal = val;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // Delete Google Drive Switch
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Delete Drive Backup",
                          style: TextStyle(
                            fontFamily: Fonts.poppinsMedium,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: const Text(
                          "Removes backup from Google Drive",
                          style: TextStyle(
                            fontFamily: Fonts.poppinsRegular,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 0.8,
                          alignment: Alignment.centerRight,
                          child: Switch(
                            activeThumbColor: const Color(0xFFC62828),
                            inactiveTrackColor: Colors.grey.shade200,
                            value: deleteDrive,
                            onChanged: (val) {
                              setState(() {
                                deleteDrive = val;
                              });
                            },
                          ),
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
                              onPressed: () => Navigator.pop(ctx),
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
                              onPressed: (!deleteLocal && !deleteDrive)
                                  ? null
                                  : () async {
                                      Navigator.pop(ctx);

                                      final success = await deleteAllData(
                                        deleteLocal: deleteLocal,
                                        deleteDrive: deleteDrive,
                                      );

                                      if (context.mounted) {
                                        if (success) {
                                          showSnackBar(context, 'Success', 'Selected data has been deleted.');
                                        } else {
                                          showSnackBar(context, 'Error', 'Database not initialized.', isError: true);
                                        }
                                      }
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
        }
      ),
    );
  }
}
