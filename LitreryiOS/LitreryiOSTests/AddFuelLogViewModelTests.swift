import Testing
@testable import LitreryiOS

@MainActor
struct AddFuelLogViewModelTests {
    private func makeViewModel(store: VehicleStore = MockVehicleStore()) -> AddFuelLogViewModel {
        AddFuelLogViewModel(vehicle: MockVehicleStore.sampleVehicles[1], store: store)
    }

    @Test func liveRecalculatesOnEverySubsequentChange() {
        let vm = makeViewModel()
        vm.kilometresText = "400"; vm.litresText = "32"
        #expect(vm.lPer100Km == 8.0)
        // A SECOND change after the first auto-calc must still recompute live.
        vm.kilometresText = "500"
        #expect(vm.lPer100Km == 6.4)
    }

    @Test func manualEditStopsAutoRecalculation() {
        let vm = makeViewModel()
        vm.kilometresText = "400"; vm.litresText = "32"
        vm.lPer100KmEditingBinding.wrappedValue = "99" // the user typing directly
        vm.kilometresText = "500"
        #expect(vm.lPer100Km == 99) // must not be overwritten
    }

    @Test func recalcButtonResumesAutoMode() {
        let vm = makeViewModel()
        vm.kilometresText = "400"; vm.litresText = "32"
        vm.lPer100KmEditingBinding.wrappedValue = "99"
        vm.recalcButtonTapped()
        #expect(vm.lPer100Km == 8.0)
    }

    @Test func missingInputsClearTheField() {
        let vm = makeViewModel()
        vm.kilometresText = "400"; vm.litresText = "32"
        vm.litresText = ""
        #expect(vm.lPer100Km == nil)
        #expect(vm.lPer100KmText.isEmpty)
    }

    /// Regression test for the real bug: on a South African phone, a fill-up typed
    /// as below was saved with km, litres, L/100km and cost all missing.
    @Test func commaDecimalFillUpSavesEveryValue() async throws {
        let store = MockVehicleStore()
        let vm = makeViewModel(store: store)
        vm.kilometresText = "421,8"
        vm.litresText = "36,39"
        vm.lPer100KmEditingBinding.wrappedValue = "8,2"
        vm.costText = "950,14"

        let saved = try #require(await vm.save())
        let log = try #require(saved.logs.last)
        #expect(log.kilometresDriven == 421.8)
        #expect(log.litres == 36.39)
        #expect(log.lPer100Km == 8.2)
        #expect(log.costZar == 950.14)
        #expect(vm.errorMessage == nil)
    }

    @Test func autoCalculatedValueSurvivesTheRoundTripThroughText() async throws {
        let vm = makeViewModel()
        vm.kilometresText = "463,9"
        vm.litresText = "35,7"
        let saved = try #require(await vm.save())
        #expect(saved.logs.last?.lPer100Km == (35.7 / 463.9 * 100 * 100).rounded() / 100)
    }

    @Test func unreadableNumberBlocksSaveInsteadOfDroppingIt() async {
        let vm = makeViewModel()
        vm.kilometresText = "463,9"
        vm.litresText = "35,7929,98"
        let saved = await vm.save()
        #expect(saved == nil)
        #expect(vm.errorMessage?.contains("Litres") == true)
    }
}

struct DecimalInputTests {
    @Test(arguments: [
        ("463,9", 463.9), ("463.9", 463.9), ("8", 8.0), ("8,2", 8.2),
        ("929,98", 929.98), ("36,39", 36.39), ("35.952", 35.952),
        ("1 056,25", 1056.25), ("1\u{00A0}056,25", 1056.25), ("1\u{202F}056,25", 1056.25),
        ("1,056.25", 1056.25), ("1.056,25", 1056.25), ("1'056.25", 1056.25),
        (" 12,5 ", 12.5), ("8,", 8.0), (",5", 0.5),
    ])
    func readsCommaOrFullStop(text: String, expected: Double) {
        #expect(DecimalInput.parse(text) == expected)
    }

    @Test(arguments: ["", "   ", ",", "abc", "12a", "35,7929,98", "1.2.3", "-5", "1e3"])
    func rejectsUnreadableText(text: String) {
        #expect(DecimalInput.parse(text) == nil)
    }

    @Test func formattedValuesReadBackUnchanged() {
        for value in [7.7, 8.63, 0.5, 12.0, 1056.25] {
            #expect(DecimalInput.parse(DecimalInput.format(value)) == value)
        }
    }

    @Test(arguments: [("26688", 26688), ("26 688", 26688), ("26,688", 26688), ("26.688", 26688)])
    func readsOdometer(text: String, expected: Int) {
        #expect(DecimalInput.parseInteger(text) == expected)
    }

    @Test func emptyIsNotUnreadable() {
        #expect(!DecimalInput.isUnreadable(""))
        #expect(!DecimalInput.isUnreadable("  "))
        #expect(DecimalInput.isUnreadable("12a"))
    }
}
