import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../splash_screen.dart';
import 'database_controller.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class SyncController extends GetxController {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
    clientId: Platform.isIOS ? '1018183671952-gp709t4r7r1shamol9qmeu85in7tvufm.apps.googleusercontent.com' : null,
  );

  Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);
  RxBool autoSyncEnabled = false.obs;
  Rx<DateTime?> lastSynced = Rx<DateTime?>(null);
  RxBool isLoadingRestore = false.obs;
  RxBool hasRestoredInSession = false.obs;

  static const String _backupFileName = 'expense_backup.json';

  @override
  void onInit() {
    super.onInit();
    final box = Hive.box('Account');
    autoSyncEnabled.value = box.get('autoSyncEnabled', defaultValue: true);

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      currentUser.value = account;
      if (account != null) {
        if (box.get('autoSyncEnabled') == null) {
          toggleAutoSync(true);
        } else if (autoSyncEnabled.value) {
          syncNow();
        }
      }
    });
    _googleSignIn.signInSilently();
  }

  void toggleAutoSync(bool value) {
    autoSyncEnabled.value = value;
    Hive.box('Account').put('autoSyncEnabled', value);
    if (autoSyncEnabled.value) {
      syncNow();
    }
  }

  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      debugPrint("Error signing in: $error");
      Get.snackbar('Sign In Failed', 'Could not connect to Google. Please ensure your device has an active internet connection and Google Services are configured properly.');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    currentUser.value = null;
    autoSyncEnabled.value = false;
    Hive.box('Account').delete('autoSyncEnabled');
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (currentUser.value == null) return null;
    final headers = await currentUser.value!.authHeaders;
    final client = GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  Future<void> syncNow() async {
    if (currentUser.value == null || SplashScreen.database == null) return;
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    try {
      final files = await driveApi.files.list(spaces: 'appDataFolder', q: "name = '$_backupFileName'");
      
      Map<String, dynamic> remoteData = {'accounts': [], 'transactions': []};
      String? remoteFileId;

      if (files.files != null && files.files!.isNotEmpty) {
        remoteFileId = files.files!.first.id;
        final drive.Media response = await driveApi.files.get(remoteFileId!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final remoteDataStr = await utf8.decodeStream(response.stream);
        remoteData = jsonDecode(remoteDataStr);
      }

      // Fetch Local
      final localAccounts = await SplashScreen.database!.rawQuery("SELECT * FROM Account");
      final localTransactions = await SplashScreen.database!.rawQuery("SELECT * FROM MyTransaction");

      // Merge Logic (Last Updated Wins for Both Tables)
      List<Map<String, dynamic>> mergedAccounts = _mergeData(remoteData['accounts'] ?? [], localAccounts);
      List<Map<String, dynamic>> mergedTransactions = _mergeData(remoteData['transactions'] ?? [], localTransactions);

      // Save Merged to Local DB
      await SplashScreen.database!.transaction((txn) async {
        await txn.rawDelete("DELETE FROM Account");
        await txn.rawDelete("DELETE FROM MyTransaction");

        for (var acc in mergedAccounts) {
          await txn.rawInsert("INSERT INTO Account (id, name, credit, debit, balance, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, 1, ?, ?)",
            [acc['id'], acc['name'], acc['credit'], acc['debit'], acc['balance'], acc['is_deleted'], acc['updated_at']]);
        }
        for (var tr in mergedTransactions) {
          await txn.rawInsert("INSERT INTO MyTransaction (id, date, AcId, detail, credit, debit, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)",
            [tr['id'], tr['date'], tr['AcId'], tr['detail'], tr['credit'], tr['debit'], tr['is_deleted'], tr['updated_at']]);
        }
      });

      // Update Drive Data
      final Map<String, dynamic> uploadMap = {
        'accounts': mergedAccounts.map((e) => {...e, 'is_synced': 1}).toList(),
        'transactions': mergedTransactions.map((e) => {...e, 'is_synced': 1}).toList()
      };
      
      final String uploadJson = jsonEncode(uploadMap);
      final List<int> bytes = utf8.encode(uploadJson);
      final media = drive.Media(Stream<List<int>>.fromIterable([bytes]), bytes.length);

      if (remoteFileId != null) {
        await driveApi.files.update(drive.File(), remoteFileId, uploadMedia: media);
      } else {
        await driveApi.files.create(drive.File()..name = _backupFileName..parents = ['appDataFolder'], uploadMedia: media);
      }

      lastSynced.value = DateTime.now();

      // Ensure UI updates instantly when remote data is downloaded!
      if (Get.isRegistered<DatabaseController>()) {
        await Get.find<DatabaseController>().selectData();
      }


      // final files1 = await driveApi.files.list(spaces: 'appDataFolder', q: "name = '$_backupFileName'");
      // if (files1.files != null && files1.files!.isNotEmpty) {
      //   final drive.Media response = await driveApi.files.get(files1.files!.first.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      //   final remoteDataStr = await utf8.decodeStream(response.stream);
      // print("new ::::::: ${jsonDecode(remoteDataStr)}");
      // }

    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  List<Map<String, dynamic>> _mergeData(List<dynamic> remote, List<Map<String, dynamic>> local) {
    Map<int, Map<String, dynamic>> mergedMap = {};
    for (var r in remote) {
      mergedMap[r['id']] = Map<String, dynamic>.from(r);
    }
    for (var l in local) {
      if (mergedMap.containsKey(l['id'])) {
        int remoteTs = mergedMap[l['id']]!['updated_at'] ?? 0;
        int localTs = l['updated_at'] ?? 0;
        if (localTs > remoteTs) {
          mergedMap[l['id']] = Map<String, dynamic>.from(l);
        }
      } else {
        mergedMap[l['id']] = Map<String, dynamic>.from(l);
      }
    }
    return mergedMap.values.toList();
  }

  Future<void> backupToDrive() async {
    if (currentUser.value == null || SplashScreen.database == null) return;
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    final localAccounts = await SplashScreen.database!.rawQuery("SELECT * FROM Account");
    final localTransactions = await SplashScreen.database!.rawQuery("SELECT * FROM MyTransaction");
    
    final Map<String, dynamic> uploadMap = {
      'accounts': localAccounts.map((e) => {...e, 'is_synced': 1}).toList(),
      'transactions': localTransactions.map((e) => {...e, 'is_synced': 1}).toList()
    };
    
    final String uploadJson = jsonEncode(uploadMap);
    final List<int> bytes = utf8.encode(uploadJson);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    final files = await driveApi.files.list(spaces: 'appDataFolder', q: "name = '$_backupFileName'");
    if (files.files != null && files.files!.isNotEmpty) {
      await driveApi.files.update(drive.File(), files.files!.first.id!, uploadMedia: media);
    } else {
      await driveApi.files.create(drive.File()..name = _backupFileName..parents = ['appDataFolder'], uploadMedia: media);
    }

    await SplashScreen.database!.rawUpdate("UPDATE Account SET is_synced=1");
    await SplashScreen.database!.rawUpdate("UPDATE MyTransaction SET is_synced=1");
    
    lastSynced.value = DateTime.now();
  }

  Future<bool> restoreFromDrive() async {
    if (currentUser.value == null || SplashScreen.database == null) return false;
    final driveApi = await _getDriveApi();
    if (driveApi == null) return false;

    try {
      final files = await driveApi.files.list(spaces: 'appDataFolder', q: "name = '$_backupFileName'");
      if (files.files == null || files.files!.isEmpty) return false;
      
      final remoteFileId = files.files!.first.id!;
      final drive.Media response = await driveApi.files.get(remoteFileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final remoteDataStr = await utf8.decodeStream(response.stream);
      final Map<String, dynamic> remoteData = jsonDecode(remoteDataStr);

      await SplashScreen.database!.transaction((txn) async {
        await txn.rawDelete("DELETE FROM Account");
        await txn.rawDelete("DELETE FROM MyTransaction");

        for (var acc in (remoteData['accounts'] ?? [])) {
          await txn.rawInsert("INSERT INTO Account (id, name, credit, debit, balance, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, 1, ?, ?)",
            [acc['id'], acc['name'], acc['credit'], acc['debit'], acc['balance'], acc['is_deleted'], acc['updated_at']]);
        }
        for (var tr in (remoteData['transactions'] ?? [])) {
          await txn.rawInsert("INSERT INTO MyTransaction (id, date, AcId, detail, credit, debit, is_synced, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)",
            [tr['id'], tr['date'], tr['AcId'], tr['detail'], tr['credit'], tr['debit'], tr['is_deleted'], tr['updated_at']]);
        }
      });
      
      if (Get.isRegistered<DatabaseController>()) {
        await Get.find<DatabaseController>().selectData();
      }
      
      return true;
    } catch(e) {
      debugPrint("Restore Error: $e");
      return false;
    }
  }

  Future<DateTime?> checkExistingBackup() async {
    if (currentUser.value == null) return null;
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;
    final files = await driveApi.files.list(spaces: 'appDataFolder', q: "name = '$_backupFileName'", $fields: "files(id, name, modifiedTime)");

    print("files ::::::: ${files.files?.first.toJson()}");

    if (files.files != null && files.files!.isNotEmpty) return files.files!.first.modifiedTime ?? DateTime.now();
    return null;
  }

  Future<void> deleteDriveBackup() async {
    if (currentUser.value == null) return;
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    try {
      final files = await driveApi.files.list(spaces: 'appDataFolder', q: "name = '$_backupFileName'");
      if (files.files != null && files.files!.isNotEmpty) {
        for (var file in files.files!) {
          await driveApi.files.delete(file.id!);
        }
      }
    } catch (e) {
      debugPrint("Delete Drive Backup Error: $e");
    }
  }
}
