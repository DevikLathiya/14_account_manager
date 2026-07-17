import 'package:account_manager/module/service/database_controller.dart';
import 'package:get/get.dart';

class BottomBarController extends GetxController {
  final DatabaseController _databaseController = Get.find<DatabaseController>();

  var currentIndex = 0.obs;
  void changePage(int index) => currentIndex.value = index;

  @override
  void onInit() {
    super.onInit();
    _databaseController.selectData();
  }
}
