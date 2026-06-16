import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/owner_provider.dart';
import 'providers/property_provider.dart';
import 'providers/tenant_provider.dart';
import 'providers/lease_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/document_provider.dart';
import 'providers/inspection_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/approval_provider.dart';
import 'providers/communication_provider.dart';
import 'providers/task_provider.dart';
import 'providers/vendor_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'services/pdf_export_service.dart';
import 'services/backup_service.dart';
import 'services/firestore_service.dart';
import 'services/firestore_sync_extension.dart';
import 'services/update_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/owner_shell.dart';
import 'screens/auth/tenant_shell.dart';
import 'screens/auth/caretaker_shell.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/properties/property_list_screen.dart';
import 'screens/tenants/tenant_list_screen.dart';
import 'screens/leases/lease_list_screen.dart';
import 'screens/payments/payment_list_screen.dart';
import 'screens/settings/late_fee_settings_screen.dart';
import 'screens/maintenance/maintenance_list_screen.dart';
import 'screens/owners/owner_list_screen.dart';
import 'screens/properties/add_edit_property_screen.dart';
import 'screens/tenants/add_edit_tenant_screen.dart';
import 'screens/leases/add_edit_lease_screen.dart';
import 'screens/documents/document_list_screen.dart';
import 'screens/inspections/inspection_list_screen.dart';
import 'screens/expenses/expense_list_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/approvals/approval_list_screen.dart';
import 'screens/communications/communication_list_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'screens/vendors/vendor_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/landlord/staff_screen.dart';
import 'screens/tenants/screening_screen.dart';
import 'screens/listings/listing_generator_screen.dart';
import 'screens/listings/listing_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await AuthService.instance.load();
  await NotificationService.instance.init();
  await PushService.instance.init();
  runApp(const RealEstateManagementApp());
}

class RealEstateManagementApp extends StatelessWidget {
  const RealEstateManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => OwnerProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => LeaseProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ApprovalProvider()),
        ChangeNotifierProvider(create: (_) => CommunicationProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'REMS',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.mode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.uninitialized:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        final role = auth.user?.role ?? 'landlord';
        switch (role) {
          case 'owner':
            return const OwnerShell();
          case 'tenant':
            return const TenantShell();
          case 'caretaker':
            return const CaretakerShell();
          default:
            return const MainShell();
        }
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _locked = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PropertyListScreen(),
    const TenantListScreen(),
    const LeaseListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) UpdateService.instance.checkOnStartup(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && AuthService.instance.lockEnabled) {
      AuthService.instance.lock();
      if (mounted) setState(() => _locked = true);
    }
    if (state == AppLifecycleState.resumed) {
      if (_locked) {
        _unlock();
      } else {
        _autoSync();
      }
    }
  }

  Future<void> _unlock() async {
    final ok = await AuthService.instance.authenticate();
    if (mounted) setState(() => _locked = !ok);
  }

  Future<void> _autoSync() async {
    try {
      await FirestoreService.instance.syncAllFromSqlite();
      await FirestoreService.instance.downloadFromFirestore();
    } catch (e) {
      debugPrint('Auto sync on resume error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (_locked)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 64),
                    const SizedBox(height: 16),
                    Text('REMS Locked',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _unlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          HapticFeedback.selectionClick();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Tenants',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Leases',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 4
          ? null
          : FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _onFabPressed(context);
              },
              child: const Icon(Icons.add),
            ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.home_work, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(authProvider.user?.name.isNotEmpty == true
                      ? authProvider.user!.name
                      : 'REMS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      )),
                  Text('Real Estate Management System',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      )),
                  Text('by NativeCodeX',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      )),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PaymentListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_outlined),
              title: const Text('Maintenance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MaintenanceListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Owners'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OwnerListScreen()),
                );
              },
            ),
            const Divider(),
            const _SectionHeader(title: 'QUICK LINKS'),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.grey),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Staff'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const StaffScreen()),
                );
              },
            ),
            const Divider(),
            const _SectionHeader(title: 'MANAGEMENT'),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Screening'),
              subtitle: const Text('Tenant background checks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ScreeningScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Documents'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DocumentListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Inspections'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InspectionListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Expenses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExpenseListScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.task_alt,
                  color:
                      context.watch<ApprovalProvider>().pendingCount > 0
                          ? Colors.orange
                          : null),
              title: Text('Approvals'),
              subtitle: context.watch<ApprovalProvider>().pendingCount > 0
                  ? Text(
                      '${context.watch<ApprovalProvider>().pendingCount} pending',
                      style: const TextStyle(fontSize: 11, color: Colors.orange))
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ApprovalListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Communications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CommunicationListScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.checklist,
                  color: context.watch<TaskProvider>().pendingCount > 0
                      ? Colors.orange
                      : null),
              title: Text('Tasks'),
              subtitle: context.watch<TaskProvider>().pendingCount > 0
                  ? Text(
                      '${context.watch<TaskProvider>().pendingCount} pending',
                      style: const TextStyle(fontSize: 11, color: Colors.orange))
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TaskListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: const Text('Vendors'),
              subtitle: const Text('Contractors, plumbers, electricians'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VendorListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('Listings'),
              subtitle: const Text('Share property listings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ListingListScreen()),
                );
              },
            ),
            const Divider(),
            const _SectionHeader(title: 'REPORTS'),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reports Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReportsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Rent Roll PDF'),
              onTap: () {
                Navigator.pop(context);
                PdfExportService.instance.exportRentRoll();
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Maintenance PDF'),
              onTap: () {
                Navigator.pop(context);
                PdfExportService.instance.exportMaintenanceReport();
              },
            ),
            const Divider(),
            const _SectionHeader(title: 'SETTINGS'),
            SwitchListTile(
              secondary: Icon(themeProvider.isDark
                  ? Icons.dark_mode
                  : Icons.light_mode),
              title: const Text('Dark Mode'),
              value: themeProvider.isDark,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                themeProvider.toggle();
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('App Lock'),
              subtitle: const Text('Lock with biometrics on minimize'),
              value: AuthService.instance.lockEnabled,
              onChanged: (value) async {
                Navigator.pop(context);
                if (value) {
                  final can = await AuthService.instance.canAuthenticate();
                  if (!can) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Biometrics not available on this device')),
                      );
                    }
                    return;
                  }
                  final ok = await AuthService.instance.authenticate();
                  if (!ok) return;
                }
                AuthService.instance.setLockEnabled(value);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text('Late Fee & Reminder'),
              subtitle: const Text('Configure late fees and rent reminders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LateFeeSettingsScreen()),
                );
              },
            ),
            const Divider(),
            const _SectionHeader(title: 'ACCOUNT'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
              },
            ),
            const Divider(),
            const _SectionHeader(title: 'DATA'),
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('Sync from Cloud'),
              onTap: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Syncing data from cloud...')),
                );
                await FirestoreService.instance.downloadFromFirestore();
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Sync complete! Pull to refresh screens.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup Database'),
              onTap: () {
                Navigator.pop(context);
                BackupService.instance.exportBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Test Reminder'),
              onTap: () {
                Navigator.pop(context);
                NotificationService.instance.showNotification(
                  id: 999,
                  title: 'Rent Reminder',
                  body: 'Test notification from REMS',
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.system_update_outlined),
              title: const Text('Check for Updates'),
              onTap: () {
                Navigator.pop(context);
                UpdateService.instance.checkForUpdates(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'REMS',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Built by NativeCodeX',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onFabPressed(BuildContext context) {
    switch (_currentIndex) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditPropertyScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditTenantScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditLeaseScreen()),
        );
        break;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
