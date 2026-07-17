import 'package:account_manager/core/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../auth_flow/unlock_screen.dart';
import '../../core/app_theme.dart';

class SecurityController extends GetxController {
  final LocalAuthentication _localAuth = LocalAuthentication();

  RxBool isBiometricLockEnabled = false.obs;
  bool isAuthenticated = false;
  bool isAuthenticating = false;
  RxBool obscureCurrent = true.obs;
  RxBool obscureNew = true.obs;
  RxBool obscureConfirm = true.obs;
  RxString errorMessage = "".obs;

  final currentPinController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final box = Hive.box('Account');
    isBiometricLockEnabled.value = box.get('isBiometricLockEnabled', defaultValue: false);
  }

  bool hasPassword() {
    final box = Hive.box('Account');
    return box.get('appPassword') != null;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> setPassword(String password) async {
    final box = Hive.box('Account');
    await box.put('appPassword', _hashPassword(password));
    isAuthenticated = true;
  }

  bool verifyPassword(String password) {
    final box = Hive.box('Account');
    final storedHash = box.get('appPassword');
    if (storedHash == null) return false;
    final success = _hashPassword(password) == storedHash;
    if (success) {
      isAuthenticated = true;
    }
    return success;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (isAuthenticating) return false;

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isAvailable && !isDeviceSupported) {
        return false;
      }

      isAuthenticating = true;
      final success = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Account Manager',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false, useErrorDialogs: true),
      );
      isAuthenticating = false;

      if (success) {
        isAuthenticated = true;
      }
      return success;
    } catch (e) {
      isAuthenticating = false;
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  Future<void> toggleBiometricLock(bool value) async {
    if (!hasPassword()) {
      isBiometricLockEnabled.value = false;
      if (Get.context != null) {
        showSnackBar(Get.context!, 'Action Required', 'Please set a password before enabling Biometric Lock.', isError: true);
      }
      return;
    }

    if (value) {
      // Prompt auth to confirm before enabling
      bool success = await authenticateWithBiometrics();
      if (success) {
        isBiometricLockEnabled.value = true;
        final box = Hive.box('Account');
        await box.put('isBiometricLockEnabled', true);
        if (Get.context != null) {
          showSnackBar(Get.context!, 'Security Enabled', 'Biometric lock has been enabled successfully.');
        }
      } else {
        isBiometricLockEnabled.value = false;
        if (Get.context != null) {
          showSnackBar(Get.context!, 'Authentication Failed', 'Could not verify credentials. Biometric lock was not enabled.', isError: true);
        }
      }
    } else {
      isBiometricLockEnabled.value = false;
      final box = Hive.box('Account');
      await box.put('isBiometricLockEnabled', false);
      if (Get.context != null) {
        showSnackBar(Get.context!, 'Security Disabled', 'Biometric lock has been disabled.');
      }
    }
  }

  void promptChangePin(BuildContext context) {
    errorMessage.value = "";
    currentPinController.clear();
    newPinController.clear();
    confirmPinController.clear();
    obscureCurrent.value = true;
    obscureNew.value = true;
    obscureConfirm.value = true;

    showDialog(
      context: context,
      builder: (ctx) => _ChangePinDialog(controller: this),
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  final SecurityController controller;
  const _ChangePinDialog({required this.controller});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  late final FocusNode _currentPinFocus;
  late final FocusNode _newPinFocus;
  late final FocusNode _confirmPinFocus;

  @override
  void initState() {
    super.initState();
    _currentPinFocus = FocusNode();
    _newPinFocus = FocusNode();
    _confirmPinFocus = FocusNode();
  }

  @override
  void dispose() {
    _currentPinFocus.dispose();
    _newPinFocus.dispose();
    _confirmPinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: MyColors.primaryColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Change Security PIN',
                    style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Dialog Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current PIN Field
                    TextField(
                      controller: widget.controller.currentPinController,
                      focusNode: _currentPinFocus,
                      onChanged: (value) {
                        if (value.length == 4) {
                          _newPinFocus.requestFocus();
                        }
                      },
                      obscureText: widget.controller.obscureCurrent.value,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 8.0, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Current PIN',
                        counterText: "",
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: MyColors.primaryColor.withValues(alpha: 0.7)),
                        suffixIcon: IconButton(
                          icon: Icon(widget.controller.obscureCurrent.value ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
                          onPressed: () => widget.controller.obscureCurrent.value = !widget.controller.obscureCurrent.value,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: MyColors.primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New PIN Field
                    TextField(
                      controller: widget.controller.newPinController,
                      focusNode: _newPinFocus,
                      onChanged: (value) {
                        if (value.length == 4) {
                          _confirmPinFocus.requestFocus();
                        }
                      },
                      obscureText: widget.controller.obscureNew.value,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 8.0, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'New PIN',
                        counterText: "",
                        prefixIcon: Icon(Icons.password_rounded, color: MyColors.primaryColor.withValues(alpha: 0.7)),
                        suffixIcon: IconButton(
                          icon: Icon(widget.controller.obscureNew.value ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
                          onPressed: () => widget.controller.obscureNew.value = !widget.controller.obscureNew.value,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: MyColors.primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm New PIN Field
                    TextField(
                      controller: widget.controller.confirmPinController,
                      focusNode: _confirmPinFocus,
                      obscureText: widget.controller.obscureConfirm.value,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 8.0, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Confirm New PIN',
                        counterText: "",
                        prefixIcon: Icon(Icons.password_rounded, color: MyColors.primaryColor.withValues(alpha: 0.7)),
                        suffixIcon: IconButton(
                          icon: Icon(widget.controller.obscureConfirm.value ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
                          onPressed: () => widget.controller.obscureConfirm.value = !widget.controller.obscureConfirm.value,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: MyColors.primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    if (widget.controller.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.controller.errorMessage.value,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MyColors.primaryColor,
                              side: BorderSide(color: MyColors.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final current = widget.controller.currentPinController.text;
                              final newPin = widget.controller.newPinController.text;
                              final confirm = widget.controller.confirmPinController.text;

                              if (!widget.controller.verifyPassword(current)) {
                                widget.controller.errorMessage.value = 'Current PIN is incorrect.';
                                return;
                              }
                              if (newPin.length != 4) {
                                widget.controller.errorMessage.value = 'New PIN must be exactly 4 digits.';
                                return;
                              }
                              if (newPin != confirm) {
                                widget.controller.errorMessage.value = 'New PINs do not match.';
                                return;
                              }

                              await widget.controller.setPassword(newPin);
                              if (context.mounted) {
                                Navigator.pop(context);
                                Get.offAll(() => const UnlockScreen());
                                showSnackBar(context, 'Success', 'PIN changed successfully! Please enter your new PIN to unlock.');
                              }
                            },
                            child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
