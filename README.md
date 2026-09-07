# Dollar Bills 💵

**Dollar Bills** is an offline-first personal finance management application built with **Flutter**, utilizing the **Trinity** reactive state management architecture and **Hive CE** for ultra-fast local persistence.

The app features an infinite calendar feed that centralizes scheduled and recurring financial movements, projects future monthly balances without double-counting, and tracks debts and debtor accounts with real-time automatic reconciliation.

---

## ✨ Features

### 📅 Centralized Recurring Movements & Infinite Calendar Feed
- **Single-Source Schedules**: Recurring transactions (daily, weekly, fixed-day monthly, end-of-month, or yearly) are stored as a single rule rather than generating redundant database entries.
- **No Artificial Date Caps**: Without an explicit end date, recurrences extend dynamically into the future indefinitely.
- **Dynamic Daily Detection**: The continuous scroll feed inspects each date in real time, rendering scheduled transactions on matching days with automatic monthly transitional headers.

### 🎯 Granular Scoped Recurring Edits & Deletions
When editing or deleting any recurring movement occurrence, users can choose:
- **Only this movement**: Skips or isolates the specific date, leaving the rest of the schedule intact.
- **This and future movements**: Closes out the current schedule before the selected date and applies changes or cuts from that date forward.
- **All movements**: Updates or deletes the entire master recurring schedule across all past and future dates.

### 💰 Accurate Balance Projections & Liquidation
- **Real Balance vs. Projected Monthly Balance**:
  - **Real**: Reflects actual cash flow from all movements that have already been liquidated.
  - **Monthly Balance**: Seamlessly projects the month-end balance by factoring in only **pending** movements, preventing double-counting.
- **Net Flow Summation**: Real-time summary cards display monthly income, monthly expenses, and net cash flow (+ / -).
- **One-Tap Liquidation**: Instantly mark any scheduled movement as cleared or revert cleared transactions.

### 💳 Debt & Debtor Account Management
- **Debts (Money You Owe)** & **Debtors (Money Owed to You)**: Create accounts with initial balances and track remaining amounts.
- **Automatic Reconciliation**: Liquidating an expense linked to a debt account automatically reduces the debt balance, while liquidating debtor transactions tracks repayments. Accounts reconcile directly against historical liquidated records.

### 🏷️ Categories & Personalization
- Organize transactions by customizable categories with custom icons and hexadecimal color accents.
- Dedicated liquidated history tab for auditing past cleared payments.

---

## 🏗️ Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Material 3)
- **State Management & Pattern**: [Trinity](https://pub.dev/packages/trinity) (Reactive Nodes, Signals, `NodeProvider`, and `SignalBuilder`)
- **Local Storage**: [Hive CE](https://pub.dev/packages/hive_ce) (Community Edition NoSQL Key-Value Store)
- **UI & Layout**: `sliver_tools`, `gap`
- **Formatting**: `intl` (Localized currency and Mexican Spanish `es_MX` date formats)

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── local/            # Data persistence and Hive box initialization
│   └── remote/           # Remote source contracts and networking foundations
├── models/
│   ├── account_model.dart    # Debt & debtor account entities
│   ├── category_model.dart   # Transaction categories with colors and icons
│   └── movement_model.dart   # Scheduled, recurring, and standalone movements
├── pages/
│   ├── accounts/         # Debt & Debtor accounts management screen
│   ├── home/             # Main navigation hub (IndexedStack + BottomBar)
│   ├── liquidated/       # Historical view of liquidated/cleared transactions
│   ├── movements/        # Infinite calendar feed, summary cards & forms
│   │   └── widgets/      # Movement cards, scope dialogs, summary cards
│   └── shared/           # Common widgets, theme colors, and formatters
├── services/
│   ├── accounts_service.dart   # Account CRUD and liquidation reconciliation
│   ├── categories_service.dart # Category persistence
│   └── movements_service.dart  # Centralized recurrence rules, scopes & balances
└── main.dart             # App entry point and theme configuration
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>=3.13.0`)
- [Dart SDK](https://dart.dev/get-dart)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/dollar_bills.git
   cd dollar_bills
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code bindings**:
   Generate Trinity readable nodes and Hive type adapters:
   ```bash
   dart run build_runner build
   ```

4. **Run tests**:
   Execute the test suite to verify recurrence algorithms, projections, and account reconciliation:
   ```bash
   flutter test
   ```

5. **Launch the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

The test suite covers:
- Centralized recurring rules (fixed day, end-of-month, weekly, yearly).
- Granular recurrence scopes (`onlyThis`, `thisAndFuture`, `all`) for editing and deleting.
- Monthly projected balance calculations without double-counting cleared income or expenses.
- Real-time debt reconciliation when linked movements are cleared.

Run the test suite anytime using:
```bash
flutter test
```

---

## 📄 License

This project is private and proprietary. All rights reserved.
