//
//  BudgetCycleCalculatorTests.swift
//  DualTallyTests
//
//  Cycle boundary resolution for the configurable month-start-day setting.
//

import Testing
import Foundation
@testable import DualTally

@Suite("BudgetCycleCalculator")
struct BudgetCycleCalculatorTests {
    private let calendar = Fixture.calendar

    @Test("A date before this month's start day belongs to last month's cycle")
    func dateBeforeStartDay() {
        let cycle = BudgetCycleCalculator.cycle(
            containing: Fixture.date(2026, 7, 3),
            startDay: 5,
            calendar: calendar
        )
        #expect(cycle.start == Fixture.date(2026, 6, 5).startOfDayIn(calendar))
        #expect(cycle.end == Fixture.date(2026, 7, 5).startOfDayIn(calendar))
    }

    @Test("A date on or after the start day belongs to this month's cycle")
    func dateOnOrAfterStartDay() {
        let cycle = BudgetCycleCalculator.cycle(
            containing: Fixture.date(2026, 7, 20),
            startDay: 5,
            calendar: calendar
        )
        #expect(cycle.start == Fixture.date(2026, 7, 5).startOfDayIn(calendar))
        #expect(cycle.end == Fixture.date(2026, 8, 5).startOfDayIn(calendar))
    }

    @Test("The start day itself is the first day of the new cycle")
    func startDayIsInclusive() {
        let cycle = BudgetCycleCalculator.cycle(
            containing: Fixture.date(2026, 7, 5),
            startDay: 5,
            calendar: calendar
        )
        #expect(cycle.start == Fixture.date(2026, 7, 5).startOfDayIn(calendar))
    }

    @Test("Start day 1 gives calendar-month cycles")
    func startDayOneMatchesCalendarMonth() {
        let cycle = BudgetCycleCalculator.cycle(
            containing: Fixture.date(2026, 7, 20),
            startDay: 1,
            calendar: calendar
        )
        #expect(cycle.start == Fixture.date(2026, 7, 1).startOfDayIn(calendar))
        #expect(cycle.end == Fixture.date(2026, 8, 1).startOfDayIn(calendar))
    }

    @Test("Out-of-range start days clamp to 1...28")
    func startDayClamps() {
        // Start day 40 clamps to 28. July 20 is before this month's 28th anchor,
        // so the cycle it falls in started on the 28th of the previous month.
        let cycle = BudgetCycleCalculator.cycle(
            containing: Fixture.date(2026, 7, 20),
            startDay: 40,
            calendar: calendar
        )
        #expect(cycle.start == Fixture.date(2026, 6, 28).startOfDayIn(calendar))
        #expect(cycle.end == Fixture.date(2026, 7, 28).startOfDayIn(calendar))
    }

    @Test("contains is start-inclusive and end-exclusive")
    func containsBoundaries() {
        let cycle = BudgetCycleCalculator.cycle(
            containing: Fixture.date(2026, 7, 20),
            startDay: 5,
            calendar: calendar
        )
        #expect(cycle.contains(cycle.start))
        #expect(!cycle.contains(cycle.end))
        #expect(cycle.contains(Fixture.date(2026, 7, 20)))
    }
}

private extension Date {
    func startOfDayIn(_ calendar: Calendar) -> Date {
        calendar.startOfDay(for: self)
    }
}
