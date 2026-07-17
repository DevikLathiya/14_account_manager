import 'package:account_manager/module/setting/botttom_bar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/app_theme.dart';
import '../service/security_controller.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final SecurityController _securityController = Get.find<SecurityController>();

  // Controllers
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  // Focus Nodes
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();

  // States
  bool _isSetupMode = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isSetupMode = !_securityController.hasPassword();

    if (!_isSetupMode && _securityController.isBiometricLockEnabled.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptBiometricUnlock();
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _attemptBiometricUnlock() async {
    bool success = await _securityController.authenticateWithBiometrics();
    if (success) {
      Get.offAll(() => const BottomBarScreen());
    }
  }

  void _handleSetupPin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.length != 4) {
      setState(() {
        _errorMessage = "PIN must be exactly 4 digits.";
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = "PINs do not match.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    await _securityController.setPassword(pin);
    Get.offAll(() => const BottomBarScreen());
  }

  void _handleUnlock() {
    final pin = _pinController.text;
    final success = _securityController.verifyPassword(pin);

    if (success) {
      Get.offAll(() => const BottomBarScreen());
    } else {
      setState(() {
        _errorMessage = "Incorrect PIN. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [MyColors.secondaryColor, MyColors.primaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset("assets/images/logo.png", height: 100, width: 100)),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  Text(
                    "Account Manager",
                    style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 26, color: Colors.white, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSetupMode ? "Setup Security PIN" : "App Locked",
                    style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // PIN Form Container (Glassmorphic look)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // PIN Field
                        TextField(
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          onChanged: (value) {
                            if (_isSetupMode && value.length == 4) {
                              _confirmPinFocusNode.requestFocus();
                            }
                          },
                          obscureText: _obscurePin,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(color: Colors.white, letterSpacing: 8.0),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: _isSetupMode ? "Enter PIN" : "Enter PIN to unlock",
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.0),
                            prefixIcon: const Icon(Icons.security_rounded, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                              onPressed: () {
                                setState(() {
                                  _obscurePin = !_obscurePin;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),

                        if (_isSetupMode) ...[
                          const SizedBox(height: 16),
                          // Confirm PIN Field (Only in Setup Mode)
                          TextField(
                            controller: _confirmPinController,
                            focusNode: _confirmPinFocusNode,
                            obscureText: _obscureConfirmPin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white, letterSpacing: 8.0),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "Confirm PIN",
                              hintStyle: const TextStyle(color: Colors.white70, letterSpacing: 0.0),
                              prefixIcon: const Icon(Icons.security_rounded, color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPin = !_obscureConfirmPin;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Button (Unlock or Create)
                        ElevatedButton(
                          onPressed: _isSetupMode ? _handleSetupPin : _handleUnlock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: MyColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(_isSetupMode ? "Set PIN" : "Unlock", style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),

                  if (!_isSetupMode && _securityController.isBiometricLockEnabled.value) ...[
                    const SizedBox(height: 24),
                    // Quick Biometric Unlock Toggle Icon
                    InkWell(
                      onTap: _attemptBiometricUnlock,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Unlock with Biometrics", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
