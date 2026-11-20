# Firebase Firestore Database Schema Architecture
**Housing Society Management System (गृहनिर्माण संस्था व्यवस्थापन प्रणाली)**

This document details the complete NoSQL schema designed for Google Cloud Firestore to support high concurrency, real-time sync, role-based security, multi-society isolation, bilingual queries, and automated accounting reconciliation.

---

## 1. High-Level Collection Hierarchy

```
societies/ {societyId}
  ├── users/ {userId}
  ├── bills/ {billId}
  ├── payments/ {paymentId}
  ├── accounting_ledger/ {ledgerEntryId}
  ├── notices/ {noticeId}
  ├── complaints/ {complaintId}
  └── visitors/ {visitorId}
```

---

## 2. Detailed Collection Schemas

### 2.1 `societies` Collection
Represents registered Apartment Housing Societies / Co-operative Housing Societies (CHS).

| Field Name | Type | Description | Example / Notes |
|---|---|---|---|
| `id` | String | Unique Society ID | `"soc_shivaji_nagar_01"` |
| `name` | String | Registered Society Name (English) | `"Shivaji Park Co-op Housing Society"` |
| `nameMr` | String | Society Name in Marathi | `"शिवाजी पार्क सहकारी गृहनिर्माण संस्था मर्यादित"` |
| `registrationNo` | String | CHS Registration Number | `"MUM/W-E/CHS/12345/2015"` |
| `address` | String | Physical postal address | `"Plot 42, Senapati Bapat Marg, Dadar, Mumbai - 400028"` |
| `upiId` | String | Official Society UPI VPA (Target for payments) | `"shivajiparkchs@sbi"` |
| `upiMerchantName` | String | Name registered with Bank UPI | `"Shivaji Park CHS Ltd"` |
| `bankDetails` | Map | Society Bank Account info | `{"bankName": "SBI", "accountNo": "30491029384", "ifsc": "SBIN0001234", "branch": "Dadar West"}` |
| `totalWings` | List<String> | Registered Wings | `["A", "B", "C"]` |
| `totalFlats` | Number | Total flat count | `72` |
| `defaultMaintenanceAmount` | Number | Base monthly fee (₹) | `2500` |
| `treasurerUid` | String | Auth UID of Treasurer | `"usr_treasurer_01"` |
| `secretaryUid` | String | Auth UID of Secretary | `"usr_secretary_01"` |
| `createdAt` | Timestamp | Timestamp of registration | `2024-01-01T00:00:00Z` |

---

### 2.2 `users` Collection
Stores user profiles and role assignments.

| Field Name | Type | Description | Options / Notes |
|---|---|---|---|
| `uid` | String | Firebase Auth UID | Primary Key |
| `societyId` | String | Associated Society ID | Foreign Key to `societies` |
| `name` | String | Member / Guard Name | `"Rajesh Arvind Deshmukh"` |
| `nameMr` | String | Name in Marathi | `"राजेश अरविंद देशमुख"` |
| `phoneNumber` | String | Mobile number (E.164) | `"+919820123456"` |
| `email` | String | Email address | `"rajesh.deshmukh@gmail.com"` |
| `role` | String | Access control role | `'admin'` (Secretary/Treasurer), `'member'`, `'guard'` |
| `residentType` | String | Tenure status | `'owner'`, `'tenant'`, `'committee_member'` |
| `flatNumber` | String | Flat number | `"A-402"` (Empty for Guard) |
| `wing` | String | Wing designation | `"A"` |
| `isActive` | Boolean | Account status | `true` |
| `fcmToken` | String | Cloud messaging token | Token string for visitor / bill push alerts |
| `createdAt` | Timestamp | Account creation date | Server timestamp |

---

### 2.3 `bills` (Maintenance Bills) Collection
Stores generated monthly maintenance bills.

| Field Name | Type | Description | Notes |
|---|---|---|---|
| `id` | String | Unique Bill ID | `"BILL-2026-11-A402"` |
| `societyId` | String | Associated Society ID | Indexed |
| `flatNumber` | String | Target flat | `"A-402"` |
| `wing` | String | Wing | `"A"` |
| `memberUid` | String | Flat owner / tenant UID | Referenced to `users` |
| `memberName` | String | Flat resident name | `"Rajesh Arvind Deshmukh"` |
| `billMonth` | Number | Billing month (1-12) | `11` |
| `billYear` | Number | Billing year | `2026` |
| `maintenanceAmount` | Number | Fixed maintenance charge (₹) | `2500` |
| `sinkingFund` | Number | Sinking fund reserve (₹) | `300` |
| `repairFund` | Number | Building repair fund (₹) | `200` |
| `waterCharges` | Number | Water / Municipal charges (₹) | `350` |
| `latePenalty` | Number | Accumulated late fee (₹) | `0` |
| `totalAmount` | Number | Total payable due (₹) | `3350` |
| `dueDate` | Timestamp | Due date before penalty | `2026-11-15T23:59:59Z` |
| `status` | String | Bill state | `'unpaid'`, `'paid'`, `'overdue'` |
| `paidAt` | Timestamp | Payment confirmation time | Set on payment |
| `paymentRef` | String | UPI UTR / Bank reference | UPI UTR number e.g. `"432490192834"` |
| `receiptNumber` | String | Auto-generated Receipt # | `"REC-2026-11-042"` |
| `receiptPdfUrl` | String | Cloud Storage URL for PDF | Auto-generated bilingual PDF |

---

### 2.4 `payments` Collection
Stores transaction proof, UPI intent callbacks, and manual reconciliations.

| Field Name | Type | Description | Notes |
|---|---|---|---|
| `id` | String | Payment ID | `"PAY-6819284"` |
| `billId` | String | Linked Maintenance Bill | Foreign Key |
| `societyId` | String | Society ID | Multi-tenant index |
| `flatNumber` | String | Flat identifier | `"A-402"` |
| `amount` | Number | Amount received (₹) | `3350.00` |
| `paymentMode` | String | Channel | `'upi_intent'`, `'dynamic_qr'`, `'cash'`, `'neft_rtgs'` |
| `upiAppName` | String | Originating App | `'Google Pay'`, `'PhonePe'`, `'Paytm'`, `'BHIM'` |
| `transactionUtr` | String | 12-digit Bank UPI UTR | Unique bank tracking number |
| `paidAt` | Timestamp | Timestamp of transaction | Time captured |
| `verifiedBy` | String | Auto / Admin confirmation | `'auto_upi'` or Admin UID |
| `ledgerEntryId` | String | Linked Ledger Entry ID | Auto-credited into accounting ledger |

---

### 2.5 `accounting_ledger` Collection
The core double-entry-ready general ledger for total society financial transparency.

| Field Name | Type | Description | Notes |
|---|---|---|---|
| `id` | String | Ledger entry UUID | `"LED-2026-11-089"` |
| `societyId` | String | Society ID | Indexed |
| `transactionDate` | Timestamp | Date of revenue / expense | Date object |
| `type` | String | Direction | `'income'` or `'expense'` |
| `category` | String | Standard Housing Category | Options below |
| `title` | String | Entry Title (English) | `"Common Area Electricity Bill (MSEB)"` |
| `titleMr` | String | Entry Title (Marathi) | `"सामायिक वीज देयक (महावितरण)"` |
| `amount` | Number | Transaction amount (₹) | `14250.00` |
| `paymentMode` | String | Source/Destination account | `'bank'`, `'cash'`, `'upi'` |
| `voucherNo` | String | Receipt / Payment Voucher # | `"PV-2026-11-014"` |
| `vendorName` | String | Payee / Payer party | `"Maharashtra State Electricity Distribution"` |
| `billAttachmentUrl`| String | Cloud Storage Photo/PDF URL | Physical paper bill/invoice scan for audit |
| `relatedBillId` | String | Linked Bill if maintenance | Nullable |
| `recordedByUid` | String | Secretary/Treasurer Auth UID | Audit trail |
| `notes` | String | Remarks / Descriptions | Optional notes |

#### Accounting Categories:
- **Income Categories:**
  - `maintenance_collection` (मासिक देखभाल वर्गणी)
  - `clubhouse_rent` (क्लबहाऊस / हॉल भाडे)
  - `parking_charges` (अतिरिक्त वाहन पार्किंग शुल्क)
  - `penalty_fines` (दंड व विलंब आकार)
  - `bank_interest` (बँक मुदत ठेव व्याज)
  - `other_income` (इतर संकीर्ण जमा)
- **Expense Categories:**
  - `security_salary` (सुरक्षा रक्षक वेतन)
  - `common_electricity` (सामायिक वीज देयक / MSEB)
  - `water_tanker` (पाण्याचे टँकर खर्च)
  - `lift_maintenance` (लिफ्ट देखभाल व एएमसी - AMC)
  - `housekeeping_cleaning` (सफाई व कचरा व्यवस्थापन)
  - `plumbing_repairs` (प्लंबिंग व ड्रेनेज दुरुस्ती)
  - `auditor_legal_fees` (हिशोब तपासणी व कायदेशीर शुल्क)
  - `festival_celebration` (सण व सांस्कृतिक कार्यक्रम)
  - `other_expense` (इतर संकीर्ण खर्च)

---

### 2.6 `notices` Collection
Digital notice board for circulars, AGM / SGM announcements, and maintenance alerts.

| Field Name | Type | Description |
|---|---|---|
| `id` | String | Notice ID (`NOT-2026-11-01`) |
| `societyId` | String | Society ID |
| `title` | String | Notice title in English |
| `titleMr` | String | Notice title in Marathi |
| `content` | String | Detailed circular message (English) |
| `contentMr` | String | Detailed circular message (Marathi) |
| `category` | String | `'meeting_agm'`, `'maintenance'`, `'emergency'`, `'general'` |
| `priority` | String | `'low'`, `'normal'`, `'high'`, `'urgent'` |
| `publishedDate` | Timestamp | Date of circular release |
| `issuedByName` | String | `"Secretary - Anil Joshi"` |
| `attachmentUrl` | String | Optional circular PDF/image attachment |

---

### 2.7 `complaints` Collection
Helpdesk ticketing system for flat members to report building issues.

| Field Name | Type | Description |
|---|---|---|
| `id` | String | Complaint ID (`TKT-2026-11-007`) |
| `societyId` | String | Society ID |
| `flatNumber` | String | Flat number (`"B-201"`) |
| `memberUid` | String | Raised by Member UID |
| `memberName` | String | Raised by Member Name |
| `category` | String | `'plumbing'`, `'electrical'`, `'cleaning'`, `'lift'`, `'security'`, `'other'` |
| `title` | String | Complaint headline |
| `description` | String | Detailed explanation |
| `photoUrl` | String | Optional image of leak / broken equipment |
| `status` | String | `'open'`, `'in_progress'`, `'resolved'`, `'closed'` |
| `priority` | String | `'low'`, `'medium'`, `'high'` |
| `createdAt` | Timestamp | Date reported |
| `resolvedAt` | Timestamp | Date fixed |
| `adminRemarks` | String | Secretary / Technician notes |

---

### 2.8 `visitors` Collection
Security gate check-in / check-out register.

| Field Name | Type | Description |
|---|---|---|
| `id` | String | Visitor Record ID (`VIS-20261120-03`) |
| `societyId` | String | Society ID |
| `visitorName` | String | Full name of visitor |
| `phoneNumber` | String | Mobile contact |
| `targetWing` | String | Wing (`"A"`) |
| `targetFlat` | String | Flat visiting (`"A-304"`) |
| `purpose` | String | `'delivery'`, `'guest'`, `'service_maid'`, `'cab'`, `'other'` |
| `vehicleNumber` | String | Optional vehicle plate number (`"MH 12 AB 1234"`) |
| `checkInTime` | Timestamp | Security gate entry time |
| `checkOutTime` | Timestamp | Exit time (nullable) |
| `guardUid` | String | Guard on duty who registered entry |
| `guardName` | String | Guard name |
| `status` | String | `'inside'`, `'checked_out'`, `'denied'` |
| `memberApproval`| String | `'approved'`, `'pending'`, `'denied'` |
| `photoUrl` | String | Visitor facial photo snap |

---

## 3. Realtime Composite Indexes Required

1. **`bills`**:
   - `societyId` ASC, `flatNumber` ASC, `status` ASC
   - `societyId` ASC, `billYear` DESC, `billMonth` DESC

2. **`accounting_ledger`**:
   - `societyId` ASC, `type` ASC, `transactionDate` DESC
   - `societyId` ASC, `transactionDate` DESC

3. **`complaints`**:
   - `societyId` ASC, `status` ASC, `createdAt` DESC
   - `societyId` ASC, `flatNumber` ASC, `createdAt` DESC

4. **`visitors`**:
   - `societyId` ASC, `status` ASC, `checkInTime` DESC
   - `societyId` ASC, `targetFlat` ASC, `checkInTime` DESC
