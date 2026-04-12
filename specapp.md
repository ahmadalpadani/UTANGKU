📱 UtangKU - Development Plan                                                                                                                            
                                                                                                                                                           
  📋 Project Overview                                                                                                                                      

  UtangKU - A Flutter-based mobile debt management application with WhatsApp integration for debt collection.

  Tech Stack:
  - Framework: Flutter (Dart)
  - Local Database: SQLite (sqflite)
  - State Management: Provider or Riverpod
  - WhatsApp Integration: url_launcher or whatsapp_unilink
  - Authentication: flutter_secure_storage + local_auth
  - Date/Time: intl, table_calendar
  - Icons: cupertino_icons or flutter_svg

  ---
  🎯 Core Features Breakdown

  1. Data Management (Utang & Piutang)

  - Add/Edit/Delete debt records
  - Store: Name, Amount, Date, Description, Category
  - Separate: Utang (you owe) vs Piutang (others owe you)

  2. Payment Status

  - Status: Belum Lunas (Unpaid) / Lunas (Paid)
  - Status change history
  - Filter by status

  3. WhatsApp Integration ⭐

  - Link debt data to device contacts
  - One-tap WhatsApp debt collection
  - Customizable message templates

  4. Reminders

  - Due date notifications
  - Payment reminders

  5. Dashboard & Statistics

  - Total unpaid debts (Utang)
  - Total unpaid receivables (Piutang)
  - Summary by period

  6. Security

  - Local database storage
  - PIN/Biometric authentication

  ---
  🏗️  Recommended Folder Structure

  lib/
  ├── main.dart
  ├── models/
  │   ├── debt_model.dart          # Data model for utang/piutang
  │   ├── payment_status.dart       # Enum for payment status
  │   └── debt_type.dart            # Enum for Utang/Piutang
  ├── database/
  │   ├── database_helper.dart      # SQLite setup
  │   └── database_service.dart     # CRUD operations
  ├── screens/
  │   ├── home/
  │   │   ├── home_screen.dart      # Dashboard
  │   │   └── statistics_card.dart
  │   ├── debt/
  │   │   ├── debt_list_screen.dart # List of all utang/piutang
  │   │   ├── add_debt_screen.dart  # Add new debt
  │   │   └── edit_debt_screen.dart # Edit existing debt
  │   ├── piutang/
  │   │   └── piutang_list_screen.dart
  │   └── settings/
  │       ├── settings_screen.dart
  │       └── pin_screen.dart
  ├── widgets/
  │   ├── debt_card.dart
  │   ├── status_badge.dart
  │   └── custom_button.dart
  ├── services/
  │   ├── whatsapp_service.dart     # WhatsApp integration
  │   ├── notification_service.dart # Reminders
  │   └── auth_service.dart         # PIN/Biometric
  ├── utils/
  │   ├── constants.dart
  │   ├── theme.dart
  │   └── formatters.dart
  └── providers/
      └── debt_provider.dart        # State management

  ---
  📅 Development Phases

  Phase 1: Project Setup & Foundation (Days 1-2)

  - Update pubspec.yaml with dependencies
  - Set up folder structure
  - Configure theme (Material Design)
  - Set up basic navigation (BottomNavigationBar)

  Dependencies to Add:
  dependencies:
    sqflite: ^2.3.0
    path: ^1.8.3
    provider: ^6.1.1
    url_launcher: ^6.2.1
    intl: ^0.19.0
    flutter_local_notifications: ^16.3.0
    flutter_secure_storage: ^9.0.0
    local_auth: ^2.1.6
    shared_preferences: ^2.2.2

  ---
  Phase 2: Database & Models (Days 3-4)

  - Create DebtModel with fields:
    - id, name, amount, type (Utang/Piutang)
    - category, description, dueDate
    - status (Lunas/Belum Lunas)
    - phoneNumber (for WhatsApp)
    - createdAt, updatedAt
  - Set up SQLite database helper
  - Implement CRUD operations
  - Add sample data for testing

  Database Schema:
  CREATE TABLE debts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    amount REAL NOT NULL,
    type TEXT NOT NULL, -- 'UTANG' or 'PIUTANG'
    category TEXT,
    description TEXT,
    due_date TEXT,
    status TEXT NOT NULL, -- 'LUNAS' or 'BELUM_LUNAS'
    phone_number TEXT,
    created_at TEXT,
    updated_at TEXT
  )

  ---
  Phase 3: Core UI Screens (Days 5-7)

  - Home/Dashboard Screen
    - Summary cards: Total Utang, Total Piutang
    - Quick action buttons (Add Utang, Add Piutang)
    - Recent transactions list
  - Debt List Screen
    - Tab view: Utang | Piutang
    - Filter by status
    - Search functionality
    - Swipe to delete/edit
  - Add/Edit Debt Screen
    - Form with validation
    - Date picker for due date
    - Phone number picker (contacts integration)
    - Save/Cancel buttons

  ---
  Phase 4: WhatsApp Integration (Days 8-9) ⭐

  - Implement phone contact picker
  - Create WhatsApp message templates
  - Add "Tagih via WhatsApp" button
  - Format message with debt details
  - Test WhatsApp integration

  Message Template Example:
  Halo {name}, ini adalah pengingat pembayaran utang sebesar Rp {amount} yang jatuh tempo pada {due_date}. Mohon segera diproses ya. Terima kasih! 🙏

  _Dikirim melalui aplikasi UtangKU_

  ---
  Phase 5: Features & Polish (Days 10-12)

  - Statistics Screen
    - Charts (using fl_chart)
    - Monthly summaries
    - Category breakdown
  - Notification Service
    - Schedule due date reminders
    - Notification permissions handling
  - Security
    - PIN setup screen
    - Biometric authentication (Face ID/Fingerprint)
    - Auto-lock after timeout

  ---
  Phase 6: Testing & Bug Fixes (Days 13-14)

  - Test all CRUD operations
  - Test WhatsApp integration
  - Test notifications
  - Edge cases (empty states, large amounts, special characters)
  - UI/UX improvements
  - Performance optimization

  ---
  Phase 7: Final Polish (Days 15)

  - App icon and splash screen
  - About screen
  - Export data (optional)
  - User guide/help section
  - Final testing

  ---
  🚀 Quick Start - What You Can Do Right Now

  Would you like me to help you with any of these tasks?

  Option A: Start with Setup

  I can update your pubspec.yaml and create the folder structure.

  Option B: Create Database Layer

  I can implement the SQLite database helper and models.

  Option C: Build First Screen

  I can create the Home/Dashboard screen with UI.

  Option D: Full Implementation

  I can guide you through building the entire app step by step.

  ---