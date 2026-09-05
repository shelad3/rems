import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class Navigation {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String routeForRole(String role) {
    switch (role) {
      case 'tenant':
        return AppRoutes.tenantHome;
      case 'caretaker':
        return AppRoutes.caretakerHome;
      case 'owner':
      case 'manager':
        return AppRoutes.ownerHome;
      case 'admin':
        return AppRoutes.adminHome;
      default:
        return AppRoutes.welcome;
    }
  }

  static void pushClearingStack(BuildContext context, String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }

  static void replace(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  static void push(BuildContext context, String route, {Object? arguments}) {
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }
}
