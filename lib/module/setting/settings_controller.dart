import 'package:account_manager/module/service/database_controller.dart';
import 'package:account_manager/module/service/sync_controller.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final syncController = Get.find<SyncController>();
  final dbController = Get.find<DatabaseController>();

  final isSyncExpanded = false.obs;

  void toggleSyncExpanded() {
    isSyncExpanded.value = !isSyncExpanded.value;
  }
}
