# DualTally

Offline-first iOS expense tracker — monthly budgeting for daily spending, plus trip ledgers with multi-person bill splitting and debt settlement.

> **Status: planning.** The specification, screen designs, and roadmap are complete; the Xcode project has not been created yet. There is nothing to build or run at this point.

## Why two ledgers

Everyday spending and group travel spending are different problems. Daily tracking is about *staying under a monthly budget in one currency*. Travel is about *who paid what, who owes whom, across currencies, often with no signal*. DualTally keeps them as two independent tabs rather than forcing one model to cover both.

## Modules

### Daily expense tracking

- Manually set a total budget for each month (no per-category budgets, no automatic carry-over)
- Log expenses with amount, category, date, paid/unpaid status, and an optional note
- **Available balance** = budget − *all* expenses, including unpaid ones (unpaid money is already committed)
- **Spent** counts only expenses marked as paid
- **Monthly review**: at month end, go through the month's expenses and flag which ones were impulse purchases in hindsight, then see the impulse share of total spending. The flag never appears in the add/edit form — you rarely think you're being impulsive in the moment
- **Reports**: bar charts across week / month / year, in three view modes — total spending, category breakdown (stacked), or a single category's trend over time
- **Lock Screen widget**: one number, the current month's available balance

### Travel bill splitting

- Create a ledger per trip with a fixed currency and a list of members
- Record each expense with a name, amount, date, who paid, and how it splits — evenly, or a custom per-person amount that must sum to the total before it can be saved
- **Member summary**: total each person's *share* across the trip (by who the expense was split to, not who fronted the cash), drilling down into the individual line items
- **Settlement**: pick any settlement currency; each expense converts using the exchange rate *from the day it happened*, not the rate on settlement day. Net each person out, then run a debt-simplification pass so everyone settles up in the fewest possible transfers
- **Works offline**: rates are fetched and cached locally when there's a connection; if a fetch fails you enter the rate by hand and it caches the same way. Recording and settling never require the network

## Screens

Low-fidelity wireframes covering both flows and every navigation transition: [DualTally 畫面線框稿](https://claude.ai/code/artifact/febc6fcc-8687-4828-9d02-5383f09246a1)

The wireframes exist to confirm information architecture and screen transitions, not final visuals. The implementation uses stock SwiftUI components (`List`, `Form`, system colors), which already follow Apple's Human Interface Guidelines.

## Tech stack

| Concern | Choice |
| --- | --- |
| UI | SwiftUI |
| Persistence | SwiftData, fully local |
| Charts | Swift Charts |
| Widget | WidgetKit (`.accessoryCircular`) |
| Minimum target | iOS 17 |
| Backend | None — the only network call is fetching historical exchange rates |

## Requirements

- A Mac with a current version of Xcode
- A free Apple ID is enough to sign and run on your own device; the paid Apple Developer Program is not required to build this project (see [Constraints](#constraints))
- An exchange rate API key, needed only for travel settlement — provider not yet selected

## Planned structure

```
DualTally/
├── DualTally/                  # Main app target
│   ├── Models/                 # SwiftData @Model types, shared with the widget
│   ├── DailyExpense/           # Daily expense module (Views/ + ViewModels/)
│   ├── TravelSplit/            # Travel split module (Views/ + ViewModels/)
│   ├── Services/               # ExchangeRateService, DebtSimplifier — UI-free, unit-testable
│   └── Shared/                 # App Group constants
├── DualTallyWidget/            # Lock Screen widget extension
└── DualTallyTests/             # Unit tests
```

Settlement math and rate handling stay out of the view layer so they can be tested against concrete numeric cases — even splits, uneven splits, and rounding edges.

## Roadmap

1. Environment setup and empty SwiftUI + SwiftData project
2. App skeleton — two independent tabs
3. Daily expense — data models
4. Daily expense — budget, add/edit, list with summary card
5. Daily expense — monthly impulse review
6. Daily expense — reports
7. Daily expense — Lock Screen widget
8. Travel — data models
9. Travel — ledgers, detail, add expense with live split validation
10. Travel — member summary and per-member detail
11. Travel — settlement (rate API, local cache, manual fallback, debt simplification)
12. Wrap-up — unit tests, data export, README

## Constraints

**Apps signed with a free Apple ID expire after 7 days** and need a reinstall from Xcode. Data survives a reinstall, but not deleting the app, so a CSV/JSON export lands in step 12 as a backup path.

Sharing the SwiftData store with the widget extension needs an App Group. This was verified to work under free "Personal Team" signing — the entitlement is present in a codesigned device build — so no paid membership is required for anything in this project.

## Documentation

[`CLAUDE.md`](CLAUDE.md) carries repository conventions and architectural context for [Claude Code](https://claude.com/claude-code).

## License

[MIT](LICENSE) © 2026 Jean (Yi-Chen) Li
