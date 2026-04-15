import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:account_manager/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'Controller Screen/sync_controller.dart';
import 'Controller Screen/database_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _promptRestore(BuildContext context, SyncController syncController, DateTime backupDate) {
    String formattedDate = DateFormat.yMMMd().add_jm().format(backupDate.toLocal());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Found'),
        content: Text('Backup found from $formattedDate. Restore? This will replace your current device data.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              Get.snackbar('Processing', 'Restoring...');
              bool success = await syncController.restoreFromDrive();
              if (success) {
                syncController.hasRestoredInSession.value = true;
                Get.snackbar('Success', 'Restore complete!');
              } else {
                Get.snackbar('Error', 'Restore failed.');
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // --- Export Data as JSON ---
  Future<void> _exportData(BuildContext context) async {
    try {
      if (SplashScreen.database == null) {
        Get.snackbar('Error', 'Database not initialized.');
        return;
      }

      final accounts = await SplashScreen.database!.rawQuery("SELECT * FROM Account WHERE is_deleted=0");
      final transactions = await SplashScreen.database!.rawQuery("SELECT * FROM MyTransaction WHERE is_deleted=0");

      final Map<String, dynamic> exportData = {'exported_at': DateTime.now().toIso8601String(), 'accounts': accounts, 'transactions': transactions};

      final String jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Convert string to bytes since it's required for saveFile on mobile
      final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final String fileName = 'account_manager_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      final String? resultPath = await FilePicker.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (resultPath == null) return; // User cancelled

      Get.snackbar('Success', 'Data exported successfully!');
    } catch (e) {
      print(e);
      Get.snackbar('Error', 'Failed to export data: $e');
    }
  }

  // --- Import Data from JSON ---
  Future<void> _importData(BuildContext context) async {
    try {
      if (SplashScreen.database == null) {
        Get.snackbar('Error', 'Database not initialized.');
        return;
      }

      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

      if (result == null) return;

      final String? filePath = result.files.single.path;
      if (filePath == null) return;

      final File file = File(filePath);
      final String jsonStr = await file.readAsString();
      final Map<String, dynamic> importData = jsonDecode(jsonStr);

      final List<dynamic> accounts = importData['accounts'] ?? [];
      final List<dynamic> transactions = importData['transactions'] ?? [];

      if (accounts.isEmpty && transactions.isEmpty) {
        Get.snackbar('Notice', 'No data found in the file.');
        return;
      }

      // Show confirmation dialog
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Data'),
          content: Text(
            'Found ${accounts.length} accounts and ${transactions.length} transactions.\n\n'
            'This will replace all your current data. Continue?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
          ],
        ),
      );

      if (confirmed != true) return;

      await SplashScreen.database!.transaction((txn) async {
        await txn.rawDelete("DELETE FROM Account");
        await txn.rawDelete("DELETE FROM MyTransaction");

        for (var acc in accounts) {
          await txn.rawInsert("INSERT INTO Account (id, name, credit, debit, balance, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [
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
            "INSERT INTO MyTransaction (id, date, AcId, detail, credit, debit, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [tr['id'], tr['date'], tr['AcId'], tr['detail'], tr['credit'], tr['debit'], tr['is_synced'] ?? 0, tr['is_deleted'] ?? 0, tr['updated_at'] ?? 0],
          );
        }
      });

      // Refresh UI
      if (Get.isRegistered<DatabaseController>()) {
        await Get.find<DatabaseController>().selectData();
      }

      // Sync imported data to Drive if connected
      if (Get.isRegistered<SyncController>()) {
        final syncCtrl = Get.find<SyncController>();
        if (syncCtrl.currentUser.value != null) {
          await syncCtrl.backupToDrive();
        }
      }

      Get.snackbar('Success', 'Data imported successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to import data: $e');
    }
  }

  // --- Delete All Data ---
  void _deleteAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all accounts and transactions?\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              if (SplashScreen.database == null) {
                Get.snackbar('Error', 'Database not initialized.');
                return;
              }

              await SplashScreen.database!.rawDelete("DELETE FROM MyTransaction");
              await SplashScreen.database!.rawDelete("DELETE FROM Account");

              // Also delete from Google Drive if connected
              if (Get.isRegistered<SyncController>()) {
                final syncCtrl = Get.find<SyncController>();
                if (syncCtrl.currentUser.value != null) {
                  await syncCtrl.deleteDriveBackup();
                }
              }

              // Refresh UI
              if (Get.isRegistered<DatabaseController>()) {
                await Get.find<DatabaseController>().selectData();
                await Get.find<DatabaseController>().totalStatement();
              }

              Get.snackbar('Done', 'All data has been deleted.');
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncController = Get.put(SyncController());

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(
        () => ListView(
          children: [
            // --- Google Account Section ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Google Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
            if (syncController.currentUser.value == null)
              ListTile(
                leading: const Icon(Icons.account_circle, size: 40),
                title: const Text('Not Connected'),
                subtitle: const Text('Connect to sync or backup data'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await syncController.signIn();
                    if (syncController.currentUser.value != null && !syncController.hasRestoredInSession.value) {
                      final backupDate = await syncController.checkExistingBackup();
                      if (backupDate != null) {
                        _promptRestore(context, syncController, backupDate);
                      }
                    }
                  },
                  child: const Text('Connect'),
                ),
              )
            else
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(syncController.currentUser.value!.photoUrl ?? ''),
                  child: syncController.currentUser.value!.photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(syncController.currentUser.value!.displayName ?? 'User'),
                subtitle: Text(syncController.currentUser.value!.email),
                trailing: TextButton(onPressed: () => syncController.signOut(), child: const Text('Disconnect')),
              ),

            const Divider(),

            // --- Sync Settings Section ---
            if (syncController.currentUser.value != null) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Sync Settings', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
              SwitchListTile(
                title: const Text('Auto-Sync'),
                subtitle: const Text('Automatically sync changes to Drive when online'),
                value: syncController.autoSyncEnabled.value,
                onChanged: (val) => syncController.toggleAutoSync(val),
              ),
              if (syncController.lastSynced.value != null)
                ListTile(title: const Text('Last Synced'), subtitle: Text(DateFormat.yMMMd().add_jm().format(syncController.lastSynced.value!.toLocal()))),

              const Divider(),

              // --- Backup & Restore Section ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Backup', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
              if (!syncController.autoSyncEnabled.value)
                ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text('Backup Now'),
                  subtitle: const Text('Manually upload data to Drive'),
                  onTap: () async {
                    Get.snackbar('Processing', 'Backing up...');
                    await syncController.backupToDrive();
                    Get.snackbar('Success', 'Backup complete!');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('Restore from Drive'),
                subtitle: const Text('Replace local data with Drive backup'),
                trailing: syncController.isLoadingRestore.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: syncController.isLoadingRestore.value
                    ? null
                    : () async {
                        syncController.isLoadingRestore.value = true;
                        try {
                          bool success = await syncController.restoreFromDrive();
                          if (success) {
                            syncController.hasRestoredInSession.value = true;
                          } else {
                            Get.snackbar('Notice', 'No backup found.');
                          }
                        } catch (e) {
                          Get.snackbar('Error', 'Ensure Drive API is enabled in Google Cloud Console!');
                        } finally {
                          syncController.isLoadingRestore.value = false;
                        }
                      },
              ),
            ],

            const Divider(),

            // --- Data Management Section ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Data Management', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.blue),
              title: const Text('Export Data'),
              subtitle: const Text('Export all data as JSON file'),
              onTap: () => _exportData(context),
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Import Data'),
              subtitle: const Text('Import data from a JSON file'),
              onTap: () => _importData(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete All Data'),
              subtitle: const Text('Permanently delete all accounts & transactions'),
              onTap: () => _deleteAllData(context),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
