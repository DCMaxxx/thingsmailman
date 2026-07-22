import Carbon
import Testing
@testable import ThingsMailman

struct MailEventBuilderTests {
    @Test func constructsPublishedMailForwardEvent() throws {
        let event = try MailEventBuilder.event(eventClass: MailEventCodes.mail, eventID: MailEventCodes.forward)
        #expect(event.eventClass == MailEventCodes.mail)
        #expect(event.eventID == MailEventCodes.forward)
    }

    @Test func propertySpecifierUsesObjectSpecifierType() {
        let descriptor = MailEventBuilder.property(MailEventCodes.selectionProperty)
        #expect(descriptor.descriptorType == OSType(typeObjectSpecifier))
    }

    @Test func everySpecifierUsesAnAbsoluteOrdinal() {
        let descriptor = MailEventBuilder.every(MailEventCodes.accountClass)
        let ordinal = descriptor.paramDescriptor(forKeyword: AEKeyword(keyAEKeyData))
        #expect(ordinal?.descriptorType == OSType(typeAbsoluteOrdinal))
        #expect(ordinal?.enumCodeValue == OSType(kAEAll))
    }

    @Test func extractsTheDirectObjectFromAnAppleEventReply() throws {
        let reply = try MailEventBuilder.event(eventClass: AEEventClass(kCoreEventClass), eventID: AEEventID(kAEAnswer))
        reply.setParam(.init(string: "Example"), forKeyword: keyDirectObject)

        #expect(try MailEventBuilder.result(from: reply).stringValue == "Example")
    }

    @Test func createInsertionUsesAnInsertionLocationDescriptor() {
        let container = MailEventBuilder.object(desiredClass: MailEventCodes.messageClass, index: 1)
        let descriptor = MailEventBuilder.insertionEnd(of: container)

        #expect(descriptor.descriptorType == OSType(typeInsertionLoc))
        #expect(descriptor.forKeyword(AEKeyword(keyAEObject))?.descriptorType == OSType(typeObjectSpecifier))
        #expect(descriptor.forKeyword(AEKeyword(keyAEPosition))?.enumCodeValue == OSType(kAEEnd))
    }

    @Test func rejectsAppleEventErrorReplies() throws {
        let reply = try MailEventBuilder.event(eventClass: AEEventClass(kCoreEventClass), eventID: AEEventID(kAEAnswer))
        reply.setParam(.init(int32: -1700), forKeyword: keyErrorNumber)

        #expect(throws: MailAutomationError.eventFailed(code: -1700)) {
            try MailEventBuilder.result(from: reply)
        }
    }
}
