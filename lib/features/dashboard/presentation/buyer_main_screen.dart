import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../marketplace/presentation/screens/home_screen.dart';
import '../../marketplace/presentation/screens/search_filter_screen.dart';
import '../../orders/presentation/screens/buyer_orders_screen.dart';
import '../../profile/presentation/screens/buyer_profile_screen.dart';

class BuyerMainScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const BuyerMainScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends ConsumerState<BuyerMainScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    SearchFilterScreen(),
    BuyerOrdersScreen(),
    BuyerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Khám phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Tìm kiếm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Đơn mua',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
