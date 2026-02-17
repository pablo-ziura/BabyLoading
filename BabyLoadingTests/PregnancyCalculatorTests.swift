@testable import BabyLoading
import XCTest

final class PregnancyCalculatorTests: XCTestCase {
    func testCalculateDueDate_NaegeleRule() {
        // Last period: 10 May 2025
        // + 7 days: 17 May
        // - 3 months: 17 Feb
        // + 1 year: 17 Feb 2026

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 5
        components.day = 10
        let lastPeriod = calendar.date(from: components)!

        let dueDate = PregnancyCalculator.calculateDueDate(lastPeriod: lastPeriod)

        let dueDateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)

        XCTAssertEqual(dueDateComponents.year, 2026)
        XCTAssertEqual(dueDateComponents.month, 2)
        XCTAssertEqual(dueDateComponents.day, 17)
    }

    func testCurrentWeek_Calculation() {
        // Last period was 21 days ago
        let calendar = Calendar.current
        let today = Date.now
        guard let lastPeriod = calendar.date(byAdding: .day, value: -21, to: today) else {
            XCTFail("Could not create date")
            return
        }

        let week = PregnancyCalculator.currentWeek(lastPeriod: lastPeriod, currentDate: today)

        XCTAssertEqual(week, 3)
    }

    func testCurrentWeek_LessThanOneWeek() {
        let calendar = Calendar.current
        let today = Date.now
        // 6 days ago
        guard let lastPeriod = calendar.date(byAdding: .day, value: -6, to: today) else { return }

        let week = PregnancyCalculator.currentWeek(lastPeriod: lastPeriod, currentDate: today)

        // 6 / 7 = 0
        XCTAssertEqual(week, 0)
    }

    func testCurrentWeek_ExactOneWeek() {
        let calendar = Calendar.current
        let today = Date.now
        // 7 days ago
        guard let lastPeriod = calendar.date(byAdding: .day, value: -7, to: today) else { return }

        let week = PregnancyCalculator.currentWeek(lastPeriod: lastPeriod, currentDate: today)

        // 7 / 7 = 1
        XCTAssertEqual(week, 1)
    }
}
