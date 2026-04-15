import 'dart:io';
import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'splash_screen.dart';

import 'Controller Screen/sync_controller.dart';
import 'Controller Screen/connectivity_service.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentsDir.path);
  await Hive.openBox('Account');
  
  Get.put(SyncController());
  Get.put(ConnectivityService());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Account Manager',
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
