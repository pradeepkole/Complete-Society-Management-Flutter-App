# SocietyGate (सोसायटी गेट)
### Complete Cross-Platform Apartment Housing Society Management Mobile App
**Built with Flutter (Android & iOS) • Bilingual English & Marathi (मराठी) • Google Firebase Backend**

---

## 🌟 Key Highlights & Modules

### 1. 👥 User Roles & Authentication
- **Multi-Role RBAC**:
  - **Society Admin (Secretary / Treasurer / मानद सचिव व खजिनदार)**: Full billing generation, expense authorization, circular issuance, balance sheet generation, and member management.
  - **Flat Members (Owners & Tenants / सदनिका सदस्य व भाडेकरू)**: View monthly bills, pay via UPI / Dynamic QR, download official PDF receipts, monitor society transparency accounts, raise complaints, approve gate visitors.
  - **Security Guard (सुरक्षा रक्षक / गेट कीपर)**: Digital visitor entry check-in, purpose logging, vehicle plate recording, real-time inside-campus list, 1-tap checkout, emergency contacts.
- **Bilingual Interface**:
  - Full native Devanagari Marathi (`mr`) and English (`en`) interface with instant language switch toggle accessible from any screen.

---

### 2. 💳 Maintenance Billing & Online UPI Payment Gateway
- **Admin Monthly Billing**: Secretary generates monthly bills with breakups: Regular Maintenance, Sinking Fund, Building Repair Fund, Water Charges, and Late Penalty.
- **Dynamic UPI QR Code**:
  - Live generated QR code adhering strictly to NPCI standards pre-filled with:
    `upi://pay?pa={societyUpiId}&pn={merchantName}&am={amount}&cu=INR&tn={billNote}&tr={billId}`
  - Pre-filled with the exact flat due amount and Society's official UPI VPA (e.g. `shivajiparkchs@sbi`).
- **Direct UPI App Intent Launch**:
  - Instant one-tap deep links to **Google Pay**, **PhonePe**, **Paytm**, and **BHIM**.
- **Automated Verification & Receipt**:
  - Once payment is verified, the bill is automatically marked as `PAID`.
  - An official bilingual PDF receipt is automatically compiled with society registration details, member name, flat breakdown, society seal, and transaction UTR.
  - **Auto-Ledger Credit**: The paid amount is immediately credited into the Society Accounting General Ledger under `cat_maintenance_collection`.

---

### 3. 📊 Transparent Society Accounting & Expense Management
- **Expense & Income Logging**:
  - Secretary/Treasurer records expenses (*Security Agency Salary, Common Electricity/MSEDCL, Water Tanker, Lift AMC, Housekeeping, Plumbing repairs*) and other incomes (*Clubhouse rent, Event contributions, Parking fees, Penalty/Fines*).
  - Mode selection (*Bank Transfer/Cheque, Cash-in-hand, UPI Online*).
  - Physical bill photo / invoice upload for statutory audit trails.
- **Real-Time Balance Sheet**:
  - Automatic calculation of **Total Income**, **Total Expenses**, and **Net Society Balance** with granular breakdown into **Bank Account Balance** and **Cash-in-Hand**.
  - Dynamic category distribution visual charts (Pie Chart & Category legends).
- **Member Transparency Dashboard**:
  - Read-only financial portal accessible to every flat member.
  - Complete list of society vouchers and direct inspection of attached vendor bills to prevent financial misappropriation.
- **Statutory Audit Export (AGM)**:
  - **PDF Export**: Generates an official Annual Audit Statement ready for General Body Meetings (AGM), Committee sign-offs, and Chartered Accountants.
  - **Excel / CSV Export**: Exports formatted tabular ledgers for spreadsheets.

---

### 4. 🏢 Core Society Features
- **Digital Notice Board**:
  - Broadcast circulars, water shutdown alerts, festival celebrations, and urgent AGM/SGM meeting notices with Devanagari Marathi translation.
- **Complaints Helpdesk**:
  - Members submit maintenance tickets categorized by *Plumbing, Electrical, Cleaning, Lift, Security, or Other* with photos.
  - Status tracking (*Open -> In Progress / Assigned -> Resolved*).
- **Security Visitor Entry Register**:
  - Guard logs incoming visitor name, mobile number, visiting flat, purpose (*Delivery, Guest, Maid, Cab, Service*), and vehicle plate.
  - Alerts flat resident with real-time **Approve Entry** / **Deny** prompt.
  - 1-tap checkout timestamp recording.

---

## 📁 Project Architecture & Folder Structure

```
Society/
├── android/
│   └── app/src/main/AndroidManifest.xml     # UPI app queries & permissions
├── ios/
│   └── Runner/Info.plist                     # Camera, photo, & UPI URL schemes
├── firestore.rules                           # Cloud Firestore role-based security rules
├── firestore_schema_documentation.md         # Full NoSQL database schema
├── pubspec.yaml                              # Flutter dependencies
├── lib/
│   ├── main.dart                             # App entry point & multi-providers
│   ├── l10n/
│   │   ├── app_strings.dart                  # Complete Marathi & English dictionary
│   │   └── language_provider.dart            # Language state management
│   ├── models/
│   │   ├── user_model.dart                   # User & Role definition
│   │   ├── society_model.dart                # Housing society profile & UPI config
│   │   ├── maintenance_bill_model.dart       # Monthly bill model & calculations
│   │   ├── ledger_entry_model.dart           # Double-entry general ledger
│   │   ├── notice_model.dart                 # Digital circulars
│   │   ├── complaint_model.dart              # Helpdesk tickets
│   │   └── visitor_model.dart                # Gate visitor records
│   ├── providers/
│   │   ├── auth_provider.dart                # Role switching & auth
│   │   ├── billing_provider.dart             # Dynamic QR, UPI launch & receipts
│   │   ├── accounting_provider.dart          # Balance sheet & audit export
│   │   ├── notice_provider.dart              # Notice broadcast
│   │   ├── complaint_provider.dart           # Ticketing workflow
│   │   └── visitor_provider.dart             # Security gate state
│   ├── services/
│   │   ├── firebase_service.dart             # Data layer with offline mock fallback
│   │   ├── upi_payment_service.dart          # NPCI UPI URL builder & launcher
│   │   ├── pdf_receipt_service.dart          # Bilingual PDF receipt generator
│   │   └── audit_export_service.dart         # AGM PDF & CSV statements
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart             # Mobile OTP / Role selection
│   │   ├── dashboard/
│   │   │   ├── main_navigation_dashboard.dart# Adaptive shell navigation
│   │   │   ├── admin_dashboard_tab.dart      # Committee management overview
│   │   │   ├── member_dashboard_tab.dart     # Resident dues, QR pay, receipts
│   │   │   └── guard_dashboard_tab.dart      # Gate entry & campus visitor counts
│   │   ├── billing/
│   │   │   ├── billing_management_screen.dart# Generate monthly bills
│   │   │   ├── member_bills_screen.dart      # Flat bills history & receipts
│   │   │   └── upi_payment_dialog.dart       # Dynamic QR & UPI intent sheet
│   │   ├── accounting/
│   │   │   ├── add_ledger_entry_screen.dart  # Voucher & bill attachment
│   │   │   ├── balance_sheet_screen.dart     # Real-time balance & charts
│   │   │   ├── member_transparency_screen.dart# Audited member read-only portal
│   │   │   └── audit_export_dialog.dart      # Export CSV / PDF for AGM
│   │   ├── notices/
│   │   │   ├── notice_board_screen.dart      # Circulars & AGM notices
│   │   │   └── add_notice_screen.dart        # Compose new circular
│   │   ├── complaints/
│   │   │   ├── complaints_screen.dart        # Ticket list & status updater
│   │   │   └── raise_complaint_screen.dart   # Member problem submission
│   │   └── visitors/
│   │       ├── visitor_log_screen.dart       # Inside campus & exit logs
│   │       └── visitor_checkin_screen.dart   # Guard fast check-in form
│   ├── widgets/
│   │   ├── custom_app_bar.dart               # Header with role & language toggle
│   │   ├── language_toggle_button.dart       # मराठी / English switcher
│   │   ├── role_badge.dart                   # Role status badge
│   │   ├── summary_card.dart                 # Financial & counter metrics card
│   │   └── dynamic_qr_widget.dart            # Live UPI QR & app launchers
│   └── utils/
│       ├── app_theme.dart                    # Material 3 Navy & Saffron theme
│       ├── constants.dart                    # Society defaults & categories
│       └── date_formatter.dart               # Currency (₹) & bilingual dates
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK `>= 3.0.0`
- Dart SDK `>= 3.0.0`
- Android Studio / Xcode

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the Application
```bash
# Run on connected Android / iOS device or emulator
flutter run
```

### 4. Zero-Config Demo Mode
The app is pre-configured with a robust offline mock database seeded with realistic data for **Shivaji Park Co-op Housing Society Ltd, Mumbai**:
- Instant one-click login for **Admin (मानद सचिव)**, **Flat Member (A-402 Rajesh Deshmukh)**, and **Security Guard (Gate #1)**.
- Live Dynamic QR rendering with exact due amounts (`₹3,350`).
- Instant simulated UPI verification that marks bills as paid and auto-credits the society accounting ledger in real-time.
- Immediate bilingual toggle between **English** and **मराठी**.
