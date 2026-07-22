import Testing
@testable import ThingsMailman

struct ThingsAddressValidatorTests {
    @Test(arguments: ["inbox@things.email", "  PRIVATE+mail@things.email  ", "a@THINGS.EMAIL"])
    func acceptsThingsAddresses(_ address: String) {
        #expect(ThingsAddressValidator.isValid(address))
    }

    @Test(arguments: ["", "@things.email", "me@example.com", "a@things.email.example", "a@@things.email"])
    func rejectsOtherValues(_ address: String) {
        #expect(!ThingsAddressValidator.isValid(address))
    }
}
