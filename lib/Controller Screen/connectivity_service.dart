import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../Controller Screen/sync_controller.dart';
import '../splash_screen.dart';

class ConnectivityService extends GetxService {
  late StreamSubscription<ConnectivityResult> _subscription;
  final SyncController _syncController = Get.find<SyncController>();

  @override
  void onInit() {
    super.onInit();
    _subscription = Connectivity().onConnectivityChanged.listen(_handleConnectionChange);
  }

  void _handleConnectionChange(ConnectivityResult result) async {
    if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
      if (_syncController.autoSyncEnabled.value && _syncController.currentUser.value != null && SplashScreen.database != null) {
        
        // Check pending accounts or transactions
        final pendingAcc = await SplashScreen.database!.rawQuery("SELECT * FROM Account WHERE is_synced=0");
        final pendingTrans = await SplashScreen.database!.rawQuery("SELECT * FROM MyTransaction WHERE is_synced=0");
        
        if (pendingAcc.isNotEmpty || pendingTrans.isNotEmpty) {
           await _syncController.syncNow();
        }
      }
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
