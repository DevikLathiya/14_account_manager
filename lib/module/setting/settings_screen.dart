import 'package:account_manager/core/app_snackbar.dart';
import 'package:account_manager/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../service/security_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<SettingsController>(
      init: SettingsController(),
      builder: (settingsController) {
        final syncController = settingsController.syncController;
        final dbController = settingsController.dbController;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'Settings',
                  style: TextStyle(fontFamily: Fonts.poppinsSemiBold, color: MyColors.white, fontSize: 20),
                ),
              ),
            ),

            backgroundColor: MyColors.primaryColor,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Google Account Section ---
                _buildSectionHeader(context, 'Google Sync & Backup'),
                _buildSectionCard(
                  children: [
                    if (syncController.currentUser.value == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: MyColors.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                              child: Icon(Icons.cloud_queue_rounded, color: MyColors.primaryColor, size: 36),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Cloud Backup & Sync',
                              style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Securely back up your accounts and transactions to Google Drive and keep them synchronized across devices.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  await syncController.signIn();
                                  if (syncController.currentUser.value != null && !syncController.hasRestoredInSession.value) {
                                    final backupDate = await syncController.checkExistingBackup();
                                    if (backupDate != null) {
                                      if (context.mounted) {
                                        dbController.promptRestore(context, syncController, backupDate);
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: const Text('Connect Google Drive', style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Connected User Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(syncController.currentUser.value!.photoUrl ?? ''),
                              child: syncController.currentUser.value!.photoUrl == null ? const Icon(Icons.person, size: 22) : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    syncController.currentUser.value!.displayName ?? 'User',
                                    style: const TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 15, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    syncController.currentUser.value!.email,
                                    style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 11, color: Colors.grey.shade500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(10),
                              ),
                              onPressed: () => syncController.signOut(),
                              icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F3F4)),

                      // Collapse/Expand Header - looks like "Last Synced" card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: InkWell(
                          onTap: () => settingsController.toggleSyncExpanded(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Icon(
                                  syncController.autoSyncEnabled.value ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                                  color: syncController.autoSyncEnabled.value ? Colors.teal.shade600 : Colors.grey.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Auto-Sync: ${syncController.autoSyncEnabled.value ? "ON" : "OFF"}',
                                  style: TextStyle(
                                    fontFamily: Fonts.poppinsMedium,
                                    fontSize: 11,
                                    color: syncController.autoSyncEnabled.value ? Colors.teal.shade700 : Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  settingsController.isSyncExpanded.value ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey.shade600,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: !settingsController.isSyncExpanded.value
                            ? const SizedBox.shrink()
                            : Column(
                                children: [
                                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F3F4)),

                                  // Auto-sync row
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    onTap: () => syncController.toggleAutoSync(!syncController.autoSyncEnabled.value),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.sync_rounded, color: Colors.teal, size: 20),
                                    ),
                                    title: const Text(
                                      'Auto-Sync',
                                      style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 14, color: Colors.black87),
                                    ),
                                    subtitle: const Text(
                                      'Sync changes to Drive when online',
                                      style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 11, color: Colors.grey),
                                    ),
                                    trailing: Transform.scale(
                                      scale: 0.8,
                                      alignment: Alignment.centerRight,
                                      child: Switch(
                                        activeThumbColor: MyColors.primaryColor,
                                        inactiveTrackColor: Colors.grey.shade200,
                                        value: syncController.autoSyncEnabled.value,
                                        onChanged: (val) => syncController.toggleAutoSync(val),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F3F4)),

                                  // Backup Now
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    onTap: syncController.isLoadingBackup.value
                                        ? null
                                        : () async {
                                            syncController.isLoadingBackup.value = true;
                                            try {
                                              await syncController.backupToDrive();
                                              if (context.mounted) {
                                                showSnackBar(context, 'Success', 'Backup complete!');
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                showSnackBar(context, 'Error', 'Backup failed.', isError: true);
                                              }
                                            } finally {
                                              syncController.isLoadingBackup.value = false;
                                            }
                                          },
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.cloud_upload_rounded, color: Colors.blue, size: 20),
                                    ),
                                    title: const Text(
                                      'Backup Now',
                                      style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 15, color: Colors.black87),
                                    ),
                                    subtitle: Text(
                                      'Manually upload local database to Drive',
                                      style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                    trailing: syncController.isLoadingBackup.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                                  ),
                                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F3F4)),

                                  // Restore Now
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    onTap: syncController.isLoadingRestore.value
                                        ? null
                                        : () async {
                                            syncController.isLoadingRestore.value = true;
                                            try {
                                              bool success = await syncController.restoreFromDrive();
                                              if (context.mounted) {
                                                if (success) {
                                                  syncController.hasRestoredInSession.value = true;
                                                  showSnackBar(context, 'Success', 'Restore complete!');
                                                } else {
                                                  showSnackBar(context, 'Notice', 'No backup found.');
                                                }
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                showSnackBar(context, 'Error', 'Ensure Drive API is enabled in Google Cloud Console!', isError: true);
                                              }
                                            } finally {
                                              syncController.isLoadingRestore.value = false;
                                            }
                                          },
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.cloud_download_rounded, color: Colors.indigo, size: 20),
                                    ),
                                    title: const Text(
                                      'Restore Now',
                                      style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 15, color: Colors.black87),
                                    ),
                                    subtitle: Text(
                                      'Replace local database with Drive backup',
                                      style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                    trailing: syncController.isLoadingRestore.value
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : null,
                                  ),

                                  if (syncController.lastSynced.value != null) ...[
                                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F3F4)),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade600, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Last Synced: ${DateFormat.yMMMd().add_jm().format(syncController.lastSynced.value!.toLocal())}',
                                              style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 10.5, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ],
                ),

                // --- Security Section ---
                _buildSectionHeader(context, 'Security'),
                _buildSectionCard(
                  children: [
                    Obx(() {
                      final securityController = Get.find<SecurityController>();
                      return Column(
                        children: [
                          ListTile(
                            onTap: () => securityController.toggleBiometricLock(!securityController.isBiometricLockEnabled.value),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: MyColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.fingerprint_rounded, color: MyColors.primaryColor, size: 20),
                            ),
                            title: Text(
                              'Fingerprint Unlock',
                              style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 15, color: Colors.black87),
                            ),
                            subtitle: Text(
                              'Enable biometric as an alternative to PIN',
                              style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade500),
                            ),
                            trailing: Transform.scale(
                              scale: 0.8,
                              alignment: Alignment.centerRight,
                              child: Switch(
                                activeThumbColor: MyColors.primaryColor,
                                inactiveTrackColor: Colors.grey.shade200,
                                value: securityController.isBiometricLockEnabled.value,
                                onChanged: (val) => securityController.toggleBiometricLock(val),
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F3F4)),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: MyColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.lock_open_rounded, color: MyColors.primaryColor, size: 20),
                            ),
                            title: Text(
                              'Change Security PIN',
                              style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 15, color: Colors.black87),
                            ),
                            subtitle: Text(
                              'Update your 4-digit access PIN',
                              style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade500),
                            ),
                            onTap: () => securityController.promptChangePin(context),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                // --- Data Management Section ---
                _buildSectionHeader(context, 'Data Management'),
                _buildSectionCard(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.upload_file_rounded, color: Colors.blueAccent, size: 20),
                      ),
                      title: Text(
                        'Export Data',
                        style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 15, color: Colors.black87),
                      ),
                      subtitle: Text(
                        'Save accounts & statements as JSON file',
                        style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade500),
                      ),
                      onTap: () => dbController.exportData(context),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F3F4)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.download_rounded, color: Colors.green, size: 20),
                      ),
                      title: Text(
                        'Import Data',
                        style: TextStyle(fontFamily: Fonts.poppinsMedium, fontSize: 15, color: Colors.black87),
                      ),
                      subtitle: Text(
                        'Import data from JSON file',
                        style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade500),
                      ),
                      onTap: () => dbController.importData(context),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F3F4)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                      ),
                      title: Text(
                        'Delete All Data',
                        style: TextStyle(fontFamily: Fonts.poppinsMedium, color: Colors.redAccent, fontSize: 15),
                      ),
                      subtitle: Text(
                        'Permanently clear local & Drive storage data',
                        style: TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 12, color: Colors.grey.shade500),
                      ),
                      onTap: () => dbController.promptDeleteAllData(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(color: MyColors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 12, letterSpacing: 1.2, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
    );
  }
}
