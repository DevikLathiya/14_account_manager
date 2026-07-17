import 'package:account_manager/core/app_theme.dart';
import 'package:account_manager/model/account_model.dart';
import 'package:account_manager/module/dashboard/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../record_detail/balance_detail.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Box box = Hive.box("Account");

  @override
  Widget build(BuildContext context) {
    return GetX(
      init: DashboardController(),
      initState: (state) => state.controller?.dataBaseController.totalStatement(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: RefreshIndicator(
            onRefresh: () => controller.dataBaseController.selectData(),
            child: CustomScrollView(
              controller: controller.scrollController,
              physics: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
              slivers: [
                SliverPersistentHeader(floating: false, pinned: true, delegate: CustomSliverAppBarDelegate(expandedHeight: 250, controller: controller)),
                SliverList(delegate: SliverChildListDelegate([SizedBox(height: 60), SizedBox()])),

                controller.getData.isEmpty
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: 50),
                              Text("No Data Found", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20)),
                              SizedBox(height: 4),
                              Text("Click On Add Button to add Account.", style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    : SliverList.separated(
                        itemCount: controller.getData.length,
                        separatorBuilder: (context, index) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final account = controller.getData[index];
                          return SizedBox(
                            child: Slidable(
                              key: ValueKey(account.id),
                              endActionPane: ActionPane(
                                motion: ScrollMotion(),
                                extentRatio: 0.25,
                                openThreshold: 0.2,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) => controller.accountDialog(context, account.id, account.name),
                                    icon: Icons.edit,
                                    autoClose: true,
                                    padding: EdgeInsets.zero,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  SizedBox(width: 10),
                                  SlidableAction(
                                    onPressed: (context) => deleteAccountDialog(context, account, controller),
                                    backgroundColor: Colors.red.shade300,
                                    icon: Icons.delete,
                                    autoClose: true,
                                    padding: EdgeInsets.zero,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),
                              child: Obx(() {
                                final String name = account.name;
                                final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

                                final int colorIndex = index % controller.avatarBgColors.length;
                                final Color bg = controller.avatarBgColors[colorIndex];
                                final Color textCol = controller.avatarTextColors[colorIndex];

                                final double balance = account.balance;
                                final String absBalStr = balance.abs() % 1 == 0 ? balance.abs().toStringAsFixed(0) : balance.abs().toStringAsFixed(2);
                                final String displayBalance = controller.isAmountVisible.value ? "${balance < 0 ? '-' : ''}₹$absBalStr" : "₹••••";

                                final double credit = account.credit;
                                final double debit = account.debit;
                                final bool showBadge = credit != debit;
                                final bool isCreditMore = credit > debit;

                                return GestureDetector(
                                  onTap: () => Get.to(BalanceDetailScreen(account))?.then((value) => controller.dataBaseController.selectData()),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                                          child: Text(
                                            firstLetter,
                                            style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: textCol, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).poppinsMedium.copyWith(fontSize: 17, color: Colors.black87),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          displayBalance,
                                          style: Theme.of(context).poppinsMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: MyColors.primaryColor),
                                        ),
                                        const SizedBox(width: 10),
                                        if (showBadge)
                                          Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isCreditMore ? const Color(0xFFD4F1D4) : const Color(0xFFF8D8D0),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isCreditMore ? "+" : "-",
                                              style: TextStyle(color: isCreditMore ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                SliverToBoxAdapter(child: SizedBox(height: 180)),
              ],
            ),
          ),
        );
      },
    );
  }

  void deleteAccountDialog(BuildContext context, AccountModel account, DashboardController controller) {
    showDialog(
      context: context,
      builder: (context) {
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
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      "Delete Account?",
                      style: TextStyle(fontFamily: Fonts.poppinsSemiBold, fontSize: 18, color: Color(0xFFC62828), letterSpacing: 0.3),
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
                        text: "Are you sure you want to delete '",
                        children: [
                          TextSpan(
                            text: account.name,
                            style: const TextStyle(fontFamily: Fonts.poppinsSemiBold, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const TextSpan(text: "' permanently? This action cannot be undone."),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: Fonts.poppinsRegular, fontSize: 14, color: Colors.black87, height: 1.5),
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
                            onPressed: () => Navigator.pop(context),
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
                            onPressed: () {
                              controller.dataBaseController.deleteData(account.id);
                              controller.dataBaseController.totalStatement();
                              Navigator.pop(context);
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
      },
    );
  }
}

class CustomSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final DashboardController controller;

  const CustomSliverAppBarDelegate({required this.expandedHeight, required this.controller});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double floatingHeight = 120;
    final double maxPadding = 20;
    final double minPadding = 0;

    final double horizontalPadding = (maxPadding * (1 - shrinkOffset / expandedHeight)).clamp(minPadding, maxPadding);

    final double top = (expandedHeight - floatingHeight - shrinkOffset).clamp(0, expandedHeight - floatingHeight);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        buildTopBar(shrinkOffset, context, top),
        Positioned(top: top, left: horizontalPadding, right: horizontalPadding, child: buildFloating(context, controller, shrinkOffset)),
      ],
    );
  }

  Widget buildTopBar(double shrinkOffset, context, double top) {
    final opacity = (1 - shrinkOffset / expandedHeight).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Container(
        height: expandedHeight,
        width: Get.width,
        padding: const EdgeInsets.only(bottom: 60),
        decoration: BoxDecoration(
          color: MyColors.primaryColor,
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              "DashBoard",
              style: TextStyle(fontFamily: Fonts.poppinsSemiBold, color: MyColors.white, fontSize: 20),
            ),
            Positioned(
              right: 24,
              child: Obx(
                () => IconButton(
                  icon: Icon(controller.isAmountVisible.value ? Icons.visibility : Icons.visibility_off, color: Colors.white, size: 24),
                  onPressed: () => controller.toggleAmountVisibility(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFloating(context, DashboardController controller, double shrinkOffset) {
    final double progress = (shrinkOffset / expandedHeight).clamp(0.0, 1.0);

    final double baseHeight = expandedHeight / 1.6;
    final double maxExtraHeight = 30;
    final double dynamicHeight = baseHeight + (maxExtraHeight * progress);

    return AnimatedContainer(
      padding: const EdgeInsets.only(left: 20, right: 20),
      height: dynamicHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      duration: const Duration(milliseconds: 200),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Overall Balance", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: MyColors.primaryColor)),
            const SizedBox(height: 6),

            Text(
              controller.isAmountVisible.value
                  ? ((controller.dataBaseController.mainBalance.value == '') ? "₹00" : "₹ ${controller.dataBaseController.mainBalance.value}")
                  : "₹ ••••",
              style: Theme.of(context).poppinsMedium.copyWith(fontSize: 20, color: MyColors.primaryColor),
            ),
            SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10, right: 10),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      textAlign: TextAlign.center,
                      controller.isAmountVisible.value ? ((controller.dataBaseController.cr.value == "null") ? "₹00" : "₹ ${controller.dataBaseController.cr.value}") : "₹ ••••",
                      style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.green),
                    ),
                  ),

                  Container(color: Colors.grey.shade300, height: 20, width: 1),

                  Expanded(
                    child: Text(
                      textAlign: TextAlign.center,
                      controller.isAmountVisible.value ? ((controller.dataBaseController.de.value == "null") ? "₹00" : "₹ ${controller.dataBaseController.de.value}") : "₹ ••••",
                      style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 30;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
