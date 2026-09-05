#!/usr/bin/env python3
"""Generate REMS project documentation PDF."""

from fpdf import FPDF
import os

class REMSDoc(FPDF):
    def __init__(self):
        super().__init__('P', 'mm', 'A4')
        self.set_auto_page_break(auto=True, margin=25)
        # Colors
        self.primary = (26, 115, 232)
        self.secondary = (0, 191, 165)
        self.dark = (33, 33, 33)
        self.gray = (117, 117, 117)
        self.light_gray = (245, 247, 250)
        self.white = (255, 255, 255)
        self.success = (76, 175, 80)
        self.warning = (255, 167, 38)
        self.error = (239, 83, 80)

    def header(self):
        if self.page_no() > 1:
            self.set_font('Helvetica', 'I', 8)
            self.set_text_color(*self.gray)
            self.cell(0, 8, 'REMS - Real Estate Management System', align='L')
            self.cell(0, 8, f'Page {self.page_no()}', align='R', new_x='LMARGIN', new_y='NEXT')
            self.line(10, 14, 200, 14)
            self.ln(6)

    def footer(self):
        self.set_y(-20)
        self.set_font('Helvetica', 'I', 7)
        self.set_text_color(*self.gray)
        self.cell(0, 10, 'Confidential - NativeCodex', align='C')

    def cover_page(self):
        self.add_page()
        self.ln(60)
        # Logo area
        self.set_fill_color(*self.primary)
        self.rounded_rect(85, 50, 40, 40, 5, 'F')
        self.set_font('Helvetica', 'B', 24)
        self.set_text_color(*self.white)
        self.set_xy(90, 58)
        self.cell(30, 24, 'REMS', align='C')
        # Title
        self.set_text_color(*self.dark)
        self.set_font('Helvetica', 'B', 32)
        self.set_xy(10, 110)
        self.cell(190, 15, 'Real Estate Management System', align='C')
        self.set_font('Helvetica', '', 14)
        self.set_text_color(*self.gray)
        self.cell(190, 10, 'Complete Project Documentation', align='C')
        self.ln(30)
        # Meta
        self.set_font('Helvetica', '', 11)
        self.set_text_color(*self.dark)
        info = [
            ('Version:', '1.0.0'),
            ('Package:', 'com.nativecodex.rems'),
            ('Platform:', 'Flutter + Firebase'),
            ('Author:', 'NativeCodex'),
            ('Date:', '2026'),
        ]
        for label, value in info:
            x = self.get_x()
            self.set_text_color(*self.gray)
            self.cell(80, 8, label, align='R')
            self.set_text_color(*self.dark)
            self.cell(5, 8, '')
            self.cell(80, 8, value)
            self.ln(8)
        # Bottom line
        self.ln(40)
        self.set_draw_color(*self.primary)
        self.set_line_width(0.5)
        self.line(60, self.get_y(), 150, self.get_y())

    def section_title(self, num, title):
        self.ln(8)
        self.set_text_color(*self.primary)
        self.set_font('Helvetica', 'B', 20)
        self.cell(0, 12, f'{num}. {title}', new_x='LMARGIN', new_y='NEXT')
        self.set_draw_color(*self.primary)
        self.set_line_width(0.8)
        self.line(10, self.get_y() + 1, 200, self.get_y() + 1)
        self.ln(8)

    def sub_title(self, title):
        self.ln(4)
        self.set_text_color(*self.dark)
        self.set_font('Helvetica', 'B', 14)
        self.cell(0, 10, title, new_x='LMARGIN', new_y='NEXT')
        self.ln(2)

    def sub_sub_title(self, title):
        self.set_text_color(*self.secondary)
        self.set_font('Helvetica', 'B', 11)
        self.cell(0, 8, title, new_x='LMARGIN', new_y='NEXT')
        self.ln(1)

    def body_text(self, text):
        self.set_text_color(*self.dark)
        self.set_font('Helvetica', '', 10)
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def bullet(self, text, indent=15):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(*self.dark)
        x = self.get_x()
        self.set_x(x + indent)
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(*self.primary)
        self.cell(5, 5.5, '- ')
        self.set_font('Helvetica', '', 10)
        self.set_text_color(*self.dark)
        w = 190 - indent - 5
        self.multi_cell(w, 5.5, text)

    def info_box(self, title, text):
        self.set_fill_color(232, 242, 254)
        self.set_draw_color(*self.primary)
        x = self.get_x()
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(*self.primary)
        self.set_x(15)
        self.cell(180, 7, f'  {title}', fill=True, new_x='LMARGIN', new_y='NEXT')
        self.set_x(15)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(*self.dark)
        self.multi_cell(180, 5, f'  {text}', fill=True)
        self.ln(4)

    def code_block(self, text):
        self.set_fill_color(245, 247, 250)
        self.set_font('Courier', '', 8)
        self.set_text_color(*self.dark)
        self.set_x(15)
        self.multi_cell(180, 4.5, text, fill=True)
        self.ln(3)

    def feature_table(self, headers, data):
        self.set_font('Helvetica', 'B', 9)
        self.set_fill_color(*self.primary)
        self.set_text_color(*self.white)
        # Headers
        col_w = 190 // len(headers)
        for i, h in enumerate(headers):
            self.cell(col_w, 8, f' {h}', fill=True, border=1)
        self.ln()
        # Data
        self.set_font('Helvetica', '', 9)
        self.set_text_color(*self.dark)
        for row_idx, row in enumerate(data):
            if row_idx % 2 == 0:
                self.set_fill_color(*self.light_gray)
            else:
                self.set_fill_color(*self.white)
            for i, cell in enumerate(row):
                self.cell(col_w, 7, f' {cell}', fill=True, border=1)
            self.ln()
        self.ln(4)

    def rounded_rect(self, x, y, w, h, r, style='F'):
        self.set_line_width(0.2)
        self.rect(x, y, w, h, style)


def build():
    pdf = REMSDoc()

    # ---- COVER ----
    pdf.cover_page()

    # ---- TABLE OF CONTENTS ----
    pdf.add_page()
    pdf.set_font('Helvetica', 'B', 24)
    pdf.set_text_color(*pdf.dark)
    pdf.cell(0, 15, 'Table of Contents', new_x='LMARGIN', new_y='NEXT')
    pdf.set_draw_color(*pdf.primary)
    pdf.line(10, pdf.get_y(), 200, pdf.get_y())
    pdf.ln(10)

    toc = [
        ('1', 'Product Overview'),
        ('2', 'Architecture & Tech Stack'),
        ('3', 'User Roles & Permissions'),
        ('4', 'Firestore Data Model'),
        ('5', 'Authentication & Security'),
        ('6', 'Feature Map by Role'),
        ('7', 'Navigation & UI Structure'),
        ('8', 'Onboarding Flow'),
        ('9', 'Tenant Journey'),
        ('10', 'Caretaker Journey'),
        ('11', 'Owner / Landlord Journey'),
        ('12', 'Admin Console'),
        ('13', 'Monetization: Free & Premium'),
        ('14', 'Folder Structure'),
        ('15', 'Firebase Services'),
        ('16', 'Cloud Functions Logic'),
        ('17', 'Phase Roadmap'),
    ]
    for num, title in toc:
        pdf.set_font('Helvetica', '', 11)
        pdf.set_text_color(*pdf.primary)
        pdf.cell(15, 9, num, align='R')
        pdf.set_text_color(*pdf.dark)
        pdf.cell(5, 9, '')
        pdf.cell(0, 9, title, new_x='LMARGIN', new_y='NEXT')
        pdf.set_draw_color(230, 230, 230)
        pdf.line(25, pdf.get_y(), 200, pdf.get_y())

    # ---- 1. PRODUCT OVERVIEW ----
    pdf.add_page()
    pdf.section_title('1', 'Product Overview')
    pdf.body_text(
        'REMS (Real Estate Management System) is a full-stack Flutter + Firebase mobile application '
        'that serves as a complete property operating system. It connects tenants, caretakers, '
        'property managers, landlords/owners, and platform administrators in a single unified '
        'experience.'
    )
    pdf.sub_title('Core Concept')
    pdf.body_text(
        'Think of the app as an operating loop: a tenant finds a unit  requests access  '
        'the caretaker/owner reviews  access is approved  the lease starts  and rent and '
        'maintenance become ongoing daily operations. Firebase keeps everything in sync.'
    )
    pdf.sub_title('Working Name')
    pdf.body_text('REMS - Real Estate Management System')
    pdf.sub_title('Package Identifier')
    pdf.code_block('com.nativecodex.rems')

    pdf.sub_title('Key Capabilities')
    items = [
        'Property discovery with search and filters',
        'Role-based access: Tenants, Caretakers, Owners, Managers, Admins',
        'Access request and approval workflow',
        'Rent tracking and payment recording',
        'Maintenance ticket management',
        'In-app messaging and announcement system',
        'Premium subscription with ad-supported free tier',
        'Real-time push notifications',
        'Multi-property portfolio management',
        'Analytics, reports, and PDF exports (premium)',
    ]
    for item in items:
        pdf.bullet(item)

    # ---- 2. ARCHITECTURE ----
    pdf.add_page()
    pdf.section_title('2', 'Architecture & Tech Stack')
    pdf.sub_title('Frontend')
    pdf.body_text(
        'Built with Flutter 3.41.x using Riverpod for state management. The app follows a '
        'clean architecture pattern with core, data, and feature layers.'
    )
    pdf.sub_title('Backend')
    pdf.body_text(
        'Firebase serves as the full backend stack: Firestore for data, Authentication for '
        'user management, Storage for media, Cloud Messaging for push notifications, Cloud '
        'Functions for backend logic, Remote Config for feature flags, and Analytics + '
        'Crashlytics for monitoring.'
    )
    pdf.sub_title('Technology Stack')
    pdf.feature_table(
        ['Layer', 'Technology', 'Purpose'],
        [
            ['UI', 'Flutter 3.41', 'Cross-platform mobile UI'],
            ['State', 'Riverpod 2.6', 'State management'],
            ['Auth', 'Firebase Auth', 'Email/Google/Phone auth'],
            ['DB', 'Cloud Firestore', 'Real-time document DB'],
            ['Storage', 'Firebase Storage', 'Images, docs, receipts'],
            ['Push', 'FCM + Local', 'Notifications'],
            ['Config', 'Remote Config', 'Feature flags, gating'],
            ['Analytics', 'Firebase Analytics', 'Usage tracking'],
            ['Crash', 'Crashlytics', 'Error reporting'],
        ]
    )

    pdf.sub_title('State Management: Riverpod')
    pdf.body_text(
        'Riverpod was chosen for its compile-time safety, testability, and clean separation '
        'of concerns. Providers are used for auth state, user data, repositories, and feature '
        'state. The app uses StreamProvider for real-time Firestore listeners, FutureProvider '
        'for one-time fetches, and ChangeNotifierProvider for auth flow state.'
    )

    # ---- 3. USER ROLES ----
    pdf.add_page()
    pdf.section_title('3', 'User Roles & Permissions')
    pdf.body_text(
        'REMS defines five distinct user roles, each with unique permissions, UI, and data scope. '
        'Access is enforced through Firestore security rules and client-side role-based routing.'
    )
    pdf.feature_table(
        ['Role', 'Scope', 'Primary Actions'],
        [
            ['Tenant', 'Own profile & unit', 'Browse, request, pay, maintain'],
            ['Caretaker', 'Assigned properties', 'Approve, manage, maintain'],
            ['Owner', 'Owned properties', 'Monitor, report, manage staff'],
            ['Manager', 'Managed properties', 'Operations oversight'],
            ['Admin', 'Entire platform', 'Users, properties, plans, audit'],
        ]
    )
    pdf.info_box('Security Principle',
        'No client-side role elevation. Payment status, approval status, lease creation, and '
        'role changes are server-controlled through Cloud Functions. Firestore rules enforce '
        'property-scoped data isolation.')

    pdf.sub_title('Role-Based Navigation')
    pdf.body_text('Each role sees a different bottom navigation bar tailored to their workflow:')
    items = [
        'Tenant: Home | Properties | Requests | Messages | Profile',
        'Caretaker: Dashboard | Requests | Units | Tasks | Profile',
        'Owner: Overview | Properties | Finance | Reports | Profile',
        'Admin: Users | Properties | Plans | Analytics | Audit',
    ]
    for item in items:
        pdf.bullet(item)

    # ---- 4. FIRESTORE DATA MODEL ----
    pdf.add_page()
    pdf.section_title('4', 'Firestore Data Model')
    pdf.body_text(
        'Cloud Firestore is the primary database, organized into 14 collections. '
        'Every collection is property-scoped, ensuring data isolation between properties '
        'and roles. Below is the complete schema.'
    )

    collections = [
        ('users', 'User profiles with role, status, subscription tier, property/unit links'),
        ('properties', 'Property metadata, owner/manager links, unit counts'),
        ('buildings', 'Building info within a property'),
        ('units', 'Individual units with rent, deposit, occupancy, status'),
        ('access_requests', 'Tenant access requests with approval workflow'),
        ('leases', 'Active and historical lease documents'),
        ('payments', 'Payment records with method, reference, receipt'),
        ('maintenance_tickets', 'Maintenance requests with priority, status, assignment'),
        ('notifications', 'Push and in-app notifications per recipient'),
        ('announcements', 'Property-wide announcements targeting audiences'),
        ('staff', 'Property staff assignments and permissions'),
        ('audit_logs', 'System-wide audit trail for compliance'),
        ('subscriptions', 'Owner subscription plans and billing'),
        ('messages', 'Direct messages between users within a property'),
    ]
    pdf.feature_table(
        ['Collection', 'Description'],
        [(c[0], c[1]) for c in collections]
    )

    pdf.sub_title('Key Data Relationships')
    pdf.body_text(
        'Properties own Buildings -> Buildings own Units. Users are linked via role-specific '
        'fields: ownerId, managerId, caretakerId, tenantId. Access requests bridge tenants '
        'to units through an approval workflow. Leases are created upon approval. Payments '
        'reference tenant, property, and unit.'
    )

    pdf.sub_sub_title('Users Collection Schema')
    pdf.code_block(
        'users/{uid}\n'
        '  fullName, phone, email, role, status\n'
        '  photoUrl, county, idNumber\n'
        '  companyName, businessRegistration (owner)\n'
        '  employmentStatus, occupation (tenant)\n'
        '  emergencyContact, nextOfKin (tenant)\n'
        '  assignedPropertyCode (caretaker)\n'
        '  currentPropertyId, currentUnitId\n'
        '  subscriptionTier (free/premium)\n'
        '  isVerified, preferredLanguage\n'
        '  createdAt, lastLoginAt'
    )

    pdf.sub_sub_title('Units Collection Schema')
    pdf.code_block(
        'units/{unitId}\n'
        '  propertyId, buildingId\n'
        '  unitNumber, unitType, bedrooms\n'
        '  rentAmount, depositAmount\n'
        '  occupied, tenantId, caretakerId\n'
        '  status (vacant/occupied/maintenance)\n'
        '  photos[], createdAt'
    )

    # ---- 5. AUTH & SECURITY ----
    pdf.add_page()
    pdf.section_title('5', 'Authentication & Security')
    pdf.sub_title('Authentication Methods')
    pdf.body_text(
        'Firebase Authentication provides three sign-in methods, all configured in the Firebase Console:'
    )
    items = [
        'Email/Password with email verification',
        'Google Sign-In (one-tap)',
        'Phone authentication with OTP verification',
    ]
    for item in items:
        pdf.bullet(item)

    pdf.sub_title('Account Status Flow')
    pdf.body_text(
        'Every new account starts with status = "pending". The user sees a limited waiting '
        'screen until an admin or owner approves them. Possible statuses:'
    )
    pdf.feature_table(
        ['Status', 'Meaning'],
        [
            ['pending', 'Awaiting approval, limited access'],
            ['active', 'Full access based on role'],
            ['rejected', 'Application denied'],
            ['suspended', 'Temporarily disabled'],
        ]
    )

    pdf.sub_title('Firestore Security Rules')
    pdf.body_text(
        'Security rules enforce strict data isolation by role and ownership scope:'
    )
    items = [
        'Tenants can ONLY read/write their own profile and requests',
        'Caretakers can ONLY access assigned properties and units',
        'Owners can ONLY access properties they own',
        'Admins can access all platform data',
        'No cross-property data leakage',
        'Payment documents are write-only through Cloud Functions',
        'No client-side role elevation or status changes',
    ]
    for item in items:
        pdf.bullet(item)

    # ---- 6. FEATURE MAP ----
    pdf.add_page()
    pdf.section_title('6', 'Feature Map by Role')
    pdf.sub_title('Tenant Features')
    pdf.feature_table(
        ['Feature', 'Free', 'Premium'],
        [
            ['Property Discovery', 'YES', 'YES'],
            ['Access Requests', 'YES', 'YES'],
            ['Rent Reminders', 'YES', 'YES'],
            ['Basic Maintenance', 'YES', 'YES'],
            ['Payment History', 'YES', 'YES'],
            ['Basic Dashboard', 'YES', 'YES'],
            ['Ads', 'Shown', 'None'],
            ['Multi-Property', '1', 'Unlimited'],
            ['Advanced Analytics', '-', 'YES'],
            ['Lease Automation', '-', 'YES'],
            ['PDF Receipts', '-', 'YES'],
            ['Smart Notifications', '-', 'YES'],
            ['AI Tools', '-', 'Phase 3'],
        ]
    )

    pdf.sub_title('Caretaker Features')
    pdf.feature_table(
        ['Feature', 'Free', 'Premium'],
        [
            ['Pending Approvals', 'YES', 'YES'],
            ['Unit Management', 'YES', 'YES'],
            ['Maintenance Queue', 'YES', 'YES'],
            ['Tenant List', 'YES', 'YES'],
            ['Basic Reports', 'YES', 'YES'],
            ['Task Assignment', '-', 'YES'],
            ['Bulk Actions', '-', 'YES'],
            ['Advanced Reports', '-', 'YES'],
        ]
    )

    pdf.sub_title('Owner Features')
    pdf.feature_table(
        ['Feature', 'Free', 'Premium'],
        [
            ['Property Overview', '1 property', 'Unlimited'],
            ['Revenue Dashboard', 'Basic', 'Advanced'],
            ['Occupancy Tracking', 'YES', 'YES'],
            ['Staff Management', '-', 'YES'],
            ['Financial Reports', '-', 'YES'],
            ['PDF Export', '-', 'YES'],
            ['Cloud Backups', '-', 'YES'],
            ['AI Predictions', '-', 'Phase 3'],
        ]
    )

    # ---- 7. NAVIGATION ----
    pdf.add_page()
    pdf.section_title('7', 'Navigation & UI Structure')
    pdf.body_text(
        'The app uses a shell-based navigation pattern where each role has its own bottom '
        'navigation bar and set of screens. Authentication state determines which shell '
        'is loaded. Routing is handled via named routes with onGenerateRoute.'
    )

    pdf.sub_title('Screen Flow Diagram')
    pdf.code_block(
        'Splash -> Welcome -> Role Selection -> Register/Login -> Verification\n'
        '                                                          |\n'
        '                          +-----------+----------+------+------+\n'
        '                          |           |          |             |\n'
        '                       Tenant    Caretaker    Owner         Admin\n'
        '                          |           |          |             |\n'
        '                    Home      Dashboard   Overview      Users\n'
        '                    Properties  Requests   Properties    Properties\n'
        '                    Requests    Units      Finance       Plans\n'
        '                    Messages    Tasks      Reports       Analytics\n'
        '                    Profile     Profile    Profile       Audit\n'
    )

    pdf.sub_title('UI Design Principles')
    items = [
        'Clean, modern Material 3 design with Inter font',
        'Role-specific color coding (blue=tenant, green=caretaker, orange=owner)',
        'Card-based layouts with rounded corners',
        'Shimmer loading states for smooth UX',
        'Premium features visually gated with badge indicators',
        'Ads placed in non-critical screens only',
        'Emergency/payment screens are ad-free',
    ]
    for item in items:
        pdf.bullet(item)

    # ---- 8. ONBOARDING ----
    pdf.add_page()
    pdf.section_title('8', 'Onboarding Flow')
    pdf.body_text(
        'The onboarding process takes a user from first launch to an active account in a '
        'series of well-defined steps.'
    )

    steps = [
        ('1. Splash Screen', 'App logo with Firebase initialization. Auto-routes to dashboard if session exists, else to Welcome screen.'),
        ('2. Welcome Screen', 'Login, Register, and Guest Viewer options. Guest mode only shows public property listings.'),
        ('3. Role Selection', 'User picks their role: Tenant, Caretaker, Owner/Landlord, or Property Manager. Role determines form fields and UI.'),
        ('4. Registration Form', 'Role-specific fields. Common: name, phone, email, password, county. Tenant adds: ID, next-of-kin, employment. Owner adds: company, business reg. Caretaker adds: property code.'),
        ('5. Verification', 'Email verification link sent. Phone OTP optional. Account status = "pending" until approved by admin/owner.'),
        ('6. Waiting Screen', 'User sees a pending-approval screen until their status changes to "active".'),
    ]
    for title, desc in steps:
        pdf.sub_sub_title(title)
        pdf.body_text(desc)

    # ---- 9. TENANT JOURNEY ----
    pdf.add_page()
    pdf.section_title('9', 'Tenant Journey')
    pdf.body_text(
        'The tenant experience is designed around discovering a property, requesting access, '
        'and then managing their rental life through the app.'
    )

    pdf.sub_title('A. Discovering Properties')
    pdf.body_text(
        'The Properties screen shows available units with search bar and filter chips '
        '(rent range, unit type, bedrooms, furnishing). Each property card shows the '
        'building name, location, available units, rent amount, and an image.'
    )

    pdf.sub_title('B. Requesting Access')
    pdf.body_text(
        'Tapping a property shows unit details: rent, deposit, type, features. The "Request '
        'Access" button creates a Firestore access_requests document with status = "pending". '
        'The tenant enters a desired move-in date.'
    )

    pdf.sub_title('C. Approval Flow')
    pdf.body_text(
        'The request is routed to the assigned caretaker and/or owner. They can approve, '
        'reject, or request more information. On approval, the system creates a lease, '
        'updates unit occupancy, links the tenant, and sends a notification.'
    )

    pdf.sub_title('D. Daily Usage')
    pdf.body_text(
        'The tenant dashboard shows: current unit info, rent due date and balance, '
        'announcements, maintenance shortcuts, recent receipts, and an ad tile (free tier). '
        'The tenant can pay rent, submit maintenance tickets, message caretaker, view lease '
        'documents, and download receipts.'
    )

    # ---- 10. CARETAKER ----
    pdf.add_page()
    pdf.section_title('10', 'Caretaker Journey')
    pdf.body_text(
        'Caretakers are the operational backbone of the app. They manage day-to-day '
        'property operations and tenant interactions.'
    )

    pdf.sub_title('Dashboard Layout')
    pdf.body_text(
        'The caretaker dashboard shows a property selector at the top, followed by summary '
        'cards with counts for pending approvals, unpaid rent, maintenance tickets, and '
        'vacant units. Below are sections for quick access to requests and maintenance.'
    )

    pdf.sub_title('Daily Workflow')
    items = [
        'Check and process pending access requests (approve/reject)',
        'Review new maintenance tickets and assign priority',
        'Post property-wide announcements',
        'Update unit occupancy and move-in/move-out status',
        'Record rent payment status and follow up on arrears',
        'Communicate with tenants via in-app messaging',
        'Generate basic occupancy and maintenance reports',
    ]
    for item in items:
        pdf.bullet(item)

    pdf.sub_title('Approval Decision Flow')
    pdf.code_block(
        'Tenant applies -> Caretaker opens request\n'
        '  -> Reviews tenant data & documents\n'
        '  -> Checks unit availability\n'
        '  -> Confirms terms\n'
        '  -> Approves or Rejects\n'
        '  -> System auto-creates lease & updates unit\n'
        '  -> Notification sent to tenant'
    )

    # ---- 11. OWNER ----
    pdf.add_page()
    pdf.section_title('11', 'Owner / Landlord Journey')
    pdf.body_text(
        'Owners get a macro-level view of their property portfolio with financial oversight '
        'and strategic decision-making tools.'
    )

    pdf.sub_title('Dashboard Layout')
    pdf.body_text(
        'The owner overview screen displays KPI cards: monthly income, occupancy rate, '
        'arrears, and active properties. A revenue chart shows trends over time. Quick '
        'action buttons let owners add properties or generate reports.'
    )

    pdf.sub_title('Owner Capabilities')
    items = [
        'View multiple properties in a single portfolio view',
        'Monitor rent collection and arrears in real-time',
        'Review maintenance spending and approve high-cost repairs',
        'Track occupancy rates across all properties',
        'Export financial statements as PDF (premium)',
        'Manage caretakers, managers, and staff roles',
        'Control premium subscription and plan upgrades',
        'View audit logs for compliance tracking',
    ]
    for item in items:
        pdf.bullet(item)

    pdf.sub_title('Premium Upsell')
    pdf.body_text(
        'Free-tier owners are limited to 1 property and basic reports. Premium unlocks '
        'unlimited properties, advanced analytics, PDF export, staff management, and AI '
        'tools (Phase 3). A premium banner appears at strategic points.'
    )

    # ---- 12. ADMIN CONSOLE ----
    pdf.add_page()
    pdf.section_title('12', 'Admin Console')
    pdf.body_text(
        'The admin panel provides full platform oversight. Admins manage users, properties, '
        'subscription plans, ad placement rules, and system analytics.'
    )

    pdf.sub_title('Admin Sections')
    admin_items = [
        ('Users', 'View all users by role and status. Approve/reject pending accounts. '
                  'Search and filter. Suspend or activate accounts.'),
        ('Properties', 'View all properties across the platform. Edit property details. '
                       'Manage property status.'),
        ('Plans', 'Configure subscription tiers: Free and Premium. Set pricing, features, '
                  'and limits per plan.'),
        ('Analytics', 'Platform-wide metrics: total users, active properties, revenue, '
                       'tenant counts. Charts for growth tracking.'),
        ('Audit', 'System audit logs with actor, action, target, and timestamp. '
                   'Export for compliance.'),
    ]
    for title, desc in admin_items:
        pdf.sub_sub_title(title)
        pdf.body_text(desc)

    # ---- 13. MONETIZATION ----
    pdf.add_page()
    pdf.section_title('13', 'Monetization: Free & Premium')
    pdf.body_text(
        'REMS uses a freemium model with ad-supported free tier and subscription-based '
        'premium. This ensures the app is accessible while generating revenue.'
    )

    pdf.sub_title('Free Tier')
    items = [
        'Ad-supported (ads in home feed, property list, reports preview)',
        '1 property limit for owners',
        'Basic reports and analytics',
        'Standard rent reminders',
        'Basic maintenance tickets',
        'Limited messaging',
        'No PDF exports',
        'No bulk actions',
    ]
    for item in items:
        pdf.bullet(item)

    pdf.sub_title('Premium Tier')
    items = [
        'No ads anywhere in the app',
        'Unlimited properties and units',
        'Advanced analytics with charts and trends',
        'PDF receipt and statement generation',
        'Lease automation and smart notifications',
        'Bulk tenant actions (messaging, maintenance)',
        'Staff task assignment and tracking',
        'Financial reports with export',
        'Cloud backups and data export',
        'AI tools in Phase 3',
    ]
    for item in items:
        pdf.bullet(item)

    pdf.sub_title('Ad Placement Rules')
    pdf.body_text(
        'Ads are carefully placed to avoid breaking trust:'
    )
    ad_items = [
        'NO ads on payment confirmation screens',
        'NO ads on emergency maintenance screens',
        'NO ads on approval decision screens',
        'NO ads on lease signing screens',
        'Ads appear on: home feed, property list, report previews, after-action screens',
    ]
    for item in ad_items:
        pdf.bullet(item)

    # ---- 14. FOLDER STRUCTURE ----
    pdf.add_page()
    pdf.section_title('14', 'Folder Structure')
    pdf.body_text(
        'The Flutter codebase follows a feature-first architecture with clean separation '
        'of concerns. Below is the complete directory tree.'
    )
    pdf.code_block(
        'lib/\n'
        '  main.dart                     # App entry point\n'
        '  core/\n'
        '    theme/                      # AppTheme, AppColors\n'
        '    constants/                  # AppConstants, FirestoreConstants\n'
        '    utils/                      # Helpers, Validators\n'
        '    routes/                     # AppRoutes\n'
        '  data/\n'
        '    models/                     # 13 domain models\n'
        '    repositories/               # 7 data repositories\n'
        '    services/                   # FirebaseService, AuthService\n'
        '  features/\n'
        '    auth/        screens/       # Splash, Welcome, Login, Register,\n'
        '                               #   RoleSelection, Verification\n'
        '                 providers/     # AuthNotifier\n'
        '    tenant/      screens/       # Home, Properties, Requests,\n'
        '                               #   Messages, Profile, Shell\n'
        '    caretaker/   screens/       # Dashboard, Requests, Units,\n'
        '                               #   Tasks, Profile, Shell\n'
        '    owner/       screens/       # Overview, Properties, Finance,\n'
        '                               #   Reports, Profile, Shell\n'
        '    admin/       screens/       # Users, Properties, Plans,\n'
        '                               #   Analytics, Audit, Shell\n'
        '    properties/  screens/       # UnitDetail\n'
        '  widgets/                      # PropertyCard, UnitCard, RequestCard,\n'
        '                               #   MaintenanceCard, AdBanner, etc.\n'
        'android/\n'
        '  app/\n'
        '    src/main/\n'
        '      kotlin/com/nativecodex/rems/   # MainActivity.kt\n'
        '      AndroidManifest.xml\n'
        '      google-services.json            # Firebase config\n'
    )

    # ---- 15. FIREBASE SERVICES ----
    pdf.add_page()
    pdf.section_title('15', 'Firebase Services')
    pdf.body_text(
        'REMS uses the following Firebase services, all integrated through the FlutterFire '
        'plugins:'
    )
    pdf.feature_table(
        ['Service', 'Usage'],
        [
            ['Authentication', 'Email/password, Google, Phone OTP'],
            ['Cloud Firestore', 'All app data (14 collections)'],
            ['Firebase Storage', 'Profile photos, property images, lease PDFs, receipts'],
            ['Cloud Messaging', 'Push notifications for approvals, payments, maintenance'],
            ['Cloud Functions', 'Backend automation: approvals, payments, reminders'],
            ['Remote Config', 'Feature flags, premium gating, ad rules'],
            ['Analytics', 'Usage tracking, funnel analysis'],
            ['Crashlytics', 'Crash reporting and stability monitoring'],
            ['App Check', 'Protect Firestore/Functions from abuse'],
        ]
    )

    pdf.sub_title('Firestore Indexes Required')
    pdf.body_text('The following composite indexes must be created in the Firebase Console:')
    pdf.code_block(
        'propertyId + status\n'
        'tenantId + createdAt\n'
        'propertyId + createdAt\n'
        'unitId + occupied\n'
        'ownerId + status\n'
        'caretakerId + status\n'
        'propertyId + priority + status\n'
        'recipientId + read + createdAt\n'
        'propertyId + unitType + rentAmount'
    )

    # ---- 16. CLOUD FUNCTIONS ----
    pdf.add_page()
    pdf.section_title('16', 'Cloud Functions Logic')
    pdf.body_text(
        'Cloud Functions provide server-side automation for critical workflows. These '
        'ensure data integrity and prevent client-side manipulation of sensitive operations.'
    )

    triggers = [
        ('onRequestCreated', 'Create notification for caretaker, notify owner, set SLA timer'),
        ('onRequestApproved', 'Create lease, update unit to occupied, link tenant, send approval notification'),
        ('onPaymentRecorded', 'Generate receipt PDF, update balance, notify tenant, update ledger'),
        ('onMaintenanceCreated', 'Notify caretaker, assign priority based on category, escalate if unresolved'),
        ('onDueDateApproaching', 'Send rent reminders, flag account for late fee, apply penalty rules if premium'),
    ]
    for fn, desc in triggers:
        pdf.sub_sub_title(fn)
        pdf.body_text(desc)

    pdf.info_box('Important',
        'Do NOT let the client directly decide: payment status, approval status, lease '
        'creation, or role elevation. All such operations MUST go through Cloud Functions '
        'or server-side security rules.')

    # ---- 17. ROADMAP ----
    pdf.add_page()
    pdf.section_title('17', 'Phase Roadmap')

    pdf.sub_title('MVP 1 - Core (Current)')
    pdf.feature_table(
        ['Feature', 'Status'],
        [
            ['User registration & auth', 'Implemented'],
            ['Role selection & profile', 'Implemented'],
            ['Property/unit browsing', 'Implemented'],
            ['Access requests & approvals', 'Implemented'],
            ['Role-based dashboards', 'Implemented'],
            ['Push notifications', 'Framework ready'],
            ['Firestore data model', 'Implemented'],
            ['Storage for images/docs', 'Service ready'],
            ['Ad placements (free tier)', 'Widget ready'],
            ['Premium gating framework', 'Widget ready'],
        ]
    )

    pdf.sub_title('MVP 2 - Operations (Next)')
    pdf.feature_table(
        ['Feature', 'Priority'],
        [
            ['Rent payments & receipts', 'High'],
            ['Lease document handling', 'High'],
            ['Visitor management', 'Medium'],
            ['Announcement system', 'Medium'],
            ['Meters & utilities', 'Medium'],
            ['Move-in / move-out flow', 'High'],
            ['Late payment penalties', 'Medium'],
            ['Multi-property dashboards', 'High'],
            ['PDF export', 'Medium'],
            ['Advanced search & filtering', 'Medium'],
            ['Enhanced analytics', 'Medium'],
        ]
    )

    pdf.sub_title('MVP 3 - Advanced Platform')
    pdf.feature_table(
        ['Feature', 'Priority'],
        [
            ['AI assistant', 'Low'],
            ['Anomaly detection', 'Low'],
            ['Predictive rent collection', 'Low'],
            ['Vacancy forecasting', 'Low'],
            ['Maintenance prediction', 'Low'],
            ['Advanced audit logs', 'Medium'],
            ['Custom branding (agencies)', 'Low'],
            ['SMS/email automation', 'Medium'],
            ['Offline sync improvements', 'Medium'],
            ['Web admin portal', 'Medium'],
            ['IoT / smart meter integration', 'Low'],
        ]
    )

    # ---- OUTPUT ----
    output_path = os.path.join(os.path.dirname(__file__), 'REMS_Project_Documentation.pdf')
    pdf.output(output_path)
    print(f'Documentation generated: {output_path}')
    print(f'Pages: {pdf.page_no()}')


if __name__ == '__main__':
    build()
