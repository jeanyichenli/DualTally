# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This repository currently contains only planning documents (`README.md`, `PLAN.md`) — no Xcode project has been created yet. There is no build, lint, or test tooling to run until the Xcode project scaffolding described below exists. When starting implementation, follow the roadmap in `PLAN.md` section 四 (環境建置 → App 骨架 → 日常記帳 → 旅遊記帳 → 收尾) in order rather than jumping ahead.

`PLAN.md` (in Traditional Chinese) is the authoritative spec for this project: it contains the finalized requirements, technical decisions, directory layout, and screen list. Read it before making architectural decisions — it has already resolved the ambiguous points in the spec through discussion with the user, so don't re-litigate decisions documented there (e.g. single-currency ledgers, "可用餘額 = 預算 − 全部支出含未付款", historical per-transaction exchange rates for settlement).

## What this project is

DualTally is an offline-first iOS SwiftUI app with two independent modules in a `TabView`:
- **日常記帳 (Daily Expense)**: monthly budgeting for single-currency daily spending, with a Lock Screen widget showing available balance.
- **旅遊分帳 (Travel Split)**: per-trip ledgers with multi-person bill splitting and debt settlement across currencies.

Not intended for App Store distribution — free Apple ID / Personal Team signing is sufficient (no paid Apple Developer Program needed).

## Technical stack (per PLAN.md 二)

- **UI**: SwiftUI, minimum iOS 17+ (required by SwiftData)
- **Persistence**: SwiftData (`@Model`), fully local/offline — no backend server
- **Charts**: Swift Charts (`BarMark`), built-in framework
- **Widget**: WidgetKit Lock Screen widget (`.accessoryInline`/`.accessoryCircular`), daily-expense module only
- **Networking**: the only network call in the app is fetching historical exchange rates for travel settlement; everything else works offline
- **Data sharing with widget**: main app and widget extension are separate targets that must share the SwiftData store via an **App Group** container — configure this in Signing & Capabilities for both targets, and call `WidgetCenter.shared.reloadTimeline` after any expense/budget mutation so the widget refreshes

## Planned architecture (per PLAN.md 五)

```
DualTally/
├── DualTally/                          # Main app target
│   ├── Models/                         # SwiftData @Model types, shared by app + widget extension
│   ├── DailyExpense/                   # Daily expense module (Views/ + ViewModels/)
│   ├── TravelSplit/                    # Travel split module (Views/ + ViewModels/)
│   ├── Services/
│   │   ├── ExchangeRateService.swift   # Exchange rate API + local cache
│   │   └── DebtSimplifier.swift        # Debt simplification algorithm (pure logic, unit-testable)
│   └── Shared/AppGroupConstants.swift  # App Group identifier / shared container path
├── DualTallyWidget/                    # Lock Screen widget extension target
└── DualTallyTests/                     # Unit tests
```

Key structural rules to preserve as the project grows:
- Keep `Services/DebtSimplifier.swift` and `Services/ExchangeRateService.swift` free of UI/SwiftUI dependencies — their core logic must stay unit-testable in isolation.
- All SwiftData `@Model` types live in `Models/` since both the app and widget extension import them; the store must live in the App Group's shared container, not the app's default container.
- The two tabs (daily expense, travel split) maintain fully independent state — don't couple them.

## Key domain logic (don't re-derive from scratch — see PLAN.md 三 for full detail)

- **可用餘額 (available balance)** = 月預算 − 全部支出（含未付款，未付款視為已預定要花的錢）; 已花費支出 only sums paid expenses.
- **衝動購物 (impulse purchase) flag**: `Expense.isImpulse` is only ever set from the monthly review screen (`MonthlyReviewView`), never from the add/edit expense form.
- **Travel settlement**: each expense converts to the settlement currency using the historical exchange rate **from the date that expense occurred** (not the settlement date's rate). Rates are cached locally per (date, currency pair) in SwiftData; if the API fetch fails, fall back to manual rate entry, which is also cached.
- **成員支出總覽 (member summary)**: aggregates `ExpenseSplit` by the person who *split* the expense, not who paid it.
- **Debt simplification**: greedy algorithm — repeatedly net the largest creditor against the largest debtor until settled, to minimize the number of transfers.
- Custom split entry must validate that per-person amounts sum to the expense total in real time, and disable Save until they match.

## Validation approach (per PLAN.md 七)

No CI/test-runner setup exists yet. Once implemented, pure-logic components (`DebtSimplifier`, balance calculations, report aggregation) should get Swift Testing/XCTest unit tests with concrete numeric cases (even splits, uneven splits, rounding edge cases). UI flows are verified manually in the Xcode Simulator; offline exchange-rate behavior should be tested with networking disabled (Simulator offline mode or Network Link Conditioner). The Lock Screen widget must be verified on a real device, since Simulator's Lock Screen preview support is limited.

## Git commit conventions

- Use **Conventional Commits** for the subject line (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, etc.).
- Write commit messages in **English**, regardless of what language the conversation happened in.
- The commit body must use **bullet points** (`-`), not prose paragraphs.
- Do **not** append a `Co-Authored-By` trailer to commits in this repository.

## Code style — Clean Code

- **Meaningful names**: variables, functions, and types must clearly express intent. No abbreviations, single-letter names, or vague placeholders (`data`, `temp`, `a1`) outside of trivial loop indices.
- **Single responsibility, small units**: each function does one thing and stays short; each type has one clear responsibility. Avoid bloated Views or ViewModels — split by responsibility (e.g. keep settlement math out of `SettlementView`, keep it in `DebtSimplifier`).
- **Don't repeat yourself**: extract shared logic into a common function/type instead of copy-pasting, but don't over-abstract for hypothetical future cases — only extract once duplication is real.
