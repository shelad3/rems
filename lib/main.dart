import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/navigation.dart';
import 'data/services/firebase_service.dart';
import 'data/services/notification_service.dart';
import 'data/models/property_model.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/guest_shell.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/phone_signup_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/verification_screen.dart';
import 'features/tenant/screens/tenant_shell.dart';
import 'features/tenant/screens/tenant_lease_screen.dart';
import 'features/caretaker/screens/caretaker_shell.dart';
import 'features/caretaker/screens/caretaker_applications_screen.dart';
import 'features/owner/screens/owner_shell.dart';
import 'features/owner/screens/assignment_requests_screen.dart';
import 'features/admin/screens/admin_shell.dart';
import 'features/properties/screens/unit_detail_screen.dart';
import 'features/properties/screens/add_unit_screen.dart';
import 'features/payments/screens/tenant_payments_screen.dart';
import 'features/payments/screens/caretaker_payments_screen.dart';
import 'features/maintenance/screens/create_ticket_screen.dart';
import 'features/maintenance/screens/tenant_tickets_screen.dart';
import 'features/maintenance/screens/caretaker_maintenance_screen.dart';
import 'features/notifications/screens/notification_center_screen.dart';
import 'features/subscriptions/screens/upgrade_screen.dart';
import 'features/owner/screens/owner_comparison_screen.dart';
import 'features/properties/screens/add_property_screen.dart';
import 'features/wallet/screens/wallet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseService = FirebaseService();
  try {
    await firebaseService
        .initialize()
        .timeout(const Duration(seconds: 8));
  } catch (_) {}
  final notificationService = NotificationService();
  try {
    await notificationService
        .initialize()
        .timeout(const Duration(seconds: 5));
  } catch (_) {}
  runApp(const ProviderScope(child: REMSApp()));
}

class REMSApp extends ConsumerWidget {
  const REMSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'REMS',
      debugShowCheckedModeBanner: false,
      navigatorKey: Navigation.navigatorKey,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case AppRoutes.splash:
            page = const SplashScreen();
            break;
          case AppRoutes.welcome:
            page = const WelcomeScreen();
            break;
          case AppRoutes.guestHome:
            page = const GuestShell();
            break;
          case AppRoutes.roleSelection:
            page = const RoleSelectionScreen();
            break;
          case AppRoutes.register:
            final role = settings.arguments as String?;
            page = RegisterScreen(initialRole: role);
            break;
          case AppRoutes.phoneSignup:
            final role = settings.arguments as String?;
            page = PhoneSignupScreen(initialRole: role);
            break;
          case AppRoutes.login:
            page = const LoginScreen();
            break;
          case AppRoutes.verification:
            page = const VerificationScreen();
            break;
          case AppRoutes.tenantHome:
            page = const TenantShell();
            break;
          case AppRoutes.tenantProperties:
            page = const TenantShell(initialIndex: 1);
            break;
          case AppRoutes.tenantRequests:
            page = const TenantShell(initialIndex: 2);
            break;
          case AppRoutes.tenantMessages:
            page = const TenantShell(initialIndex: 3);
            break;
          case AppRoutes.tenantProfile:
            page = const TenantShell(initialIndex: 4);
            break;
          case AppRoutes.caretakerHome:
            page = const CaretakerShell();
            break;
          case AppRoutes.caretakerRequests:
            page = const CaretakerShell(initialIndex: 1);
            break;
          case AppRoutes.caretakerUnits:
            page = const CaretakerShell(initialIndex: 2);
            break;
          case AppRoutes.caretakerJobs:
            page = const CaretakerShell(initialIndex: 3);
            break;
          case AppRoutes.caretakerTasks:
            page = const CaretakerShell(initialIndex: 4);
            break;
          case AppRoutes.caretakerProfile:
            page = const CaretakerShell(initialIndex: 5);
            break;
          case AppRoutes.ownerHome:
            page = const OwnerShell();
            break;
          case AppRoutes.ownerProperties:
            page = const OwnerShell(initialIndex: 1);
            break;
          case AppRoutes.ownerFinance:
            page = const OwnerShell(initialIndex: 2);
            break;
          case AppRoutes.ownerReports:
            page = const OwnerShell(initialIndex: 3);
            break;
          case AppRoutes.ownerProfile:
            page = const OwnerShell(initialIndex: 4);
            break;
          case AppRoutes.adminHome:
            page = const AdminShell();
            break;
          case AppRoutes.adminUsers:
            page = const AdminShell(initialIndex: 0);
            break;
          case AppRoutes.adminProperties:
            page = const AdminShell(initialIndex: 1);
            break;
          case AppRoutes.adminPlans:
            page = const AdminShell(initialIndex: 2);
            break;
          case AppRoutes.adminAnalytics:
            page = const AdminShell(initialIndex: 3);
            break;
          case AppRoutes.adminAudit:
            page = const AdminShell(initialIndex: 4);
            break;
          case AppRoutes.unitDetail:
            final property = settings.arguments as PropertyModel;
            page = UnitDetailScreen(property: property);
            break;
          case AppRoutes.addUnit:
            final property = settings.arguments as PropertyModel;
            page = AddUnitScreen(property: property);
            break;
          case AppRoutes.addProperty:
            page = const AddPropertyScreen();
            break;
          case AppRoutes.tenantLease:
            page = const TenantLeaseScreen();
            break;
          case AppRoutes.tenantPayments:
            page = const TenantPaymentsScreen();
            break;
          case AppRoutes.tenantTickets:
            page = const TenantTicketsScreen();
            break;
          case AppRoutes.createTicket:
            page = const CreateTicketScreen();
            break;
          case AppRoutes.caretakerPayments:
            page = const CaretakerPaymentsScreen();
            break;
          case AppRoutes.caretakerMaintenance:
            page = const CaretakerMaintenanceScreen();
            break;
          case AppRoutes.notificationCenter:
            page = const NotificationCenterScreen();
            break;
          case AppRoutes.upgrade:
            page = const UpgradeScreen();
            break;
          case AppRoutes.ownerCompare:
            page = const OwnerComparisonScreen();
            break;
          case AppRoutes.wallet:
            page = const WalletScreen();
            break;
          case AppRoutes.caretakerApplications:
            page = const CaretakerApplicationsScreen();
            break;
          case AppRoutes.assignmentRequests:
            page = const AssignmentRequestsScreen();
            break;
          default:
            page = const SplashScreen();
        }
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}
