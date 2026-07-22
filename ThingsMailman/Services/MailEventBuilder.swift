import AppKit
import Carbon

enum MailEventBuilder {
    static func result(from reply: NSAppleEventDescriptor) throws -> NSAppleEventDescriptor {
        if let error = reply.paramDescriptor(forKeyword: keyErrorNumber), error.int32Value != noErr {
            throw MailAutomationError.eventFailed(code: Int(error.int32Value))
        }
        return reply.paramDescriptor(forKeyword: keyDirectObject) ?? reply
    }

    static func event(eventClass: AEEventClass, eventID: AEEventID) throws -> NSAppleEventDescriptor {
        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.mail")
        return NSAppleEventDescriptor(
            eventClass: eventClass,
            eventID: eventID,
            targetDescriptor: target,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
    }

    static func property(_ code: DescType, of container: NSAppleEventDescriptor? = nil) -> NSAppleEventDescriptor {
        objectSpecifier(
            desiredClass: DescType(typeProperty),
            container: container,
            keyForm: DescType(formPropertyID),
            keyData: .init(typeCode: code)
        )
    }

    static func object(
        desiredClass: DescType,
        id: String,
        container: NSAppleEventDescriptor? = nil
    ) -> NSAppleEventDescriptor {
        objectSpecifier(
            desiredClass: desiredClass,
            container: container,
            keyForm: DescType(formUniqueID),
            keyData: .init(string: id)
        )
    }

    static func object(
        desiredClass: DescType,
        name: String,
        container: NSAppleEventDescriptor? = nil
    ) -> NSAppleEventDescriptor {
        objectSpecifier(
            desiredClass: desiredClass,
            container: container,
            keyForm: DescType(formName),
            keyData: .init(string: name)
        )
    }

    static func object(
        desiredClass: DescType,
        index: Int,
        container: NSAppleEventDescriptor? = nil
    ) -> NSAppleEventDescriptor {
        objectSpecifier(
            desiredClass: desiredClass,
            container: container,
            keyForm: DescType(formAbsolutePosition),
            keyData: .init(int32: Int32(index))
        )
    }

    static func every(_ desiredClass: DescType, of container: NSAppleEventDescriptor? = nil) -> NSAppleEventDescriptor {
        objectSpecifier(
            desiredClass: desiredClass,
            container: container,
            keyForm: DescType(formAbsolutePosition),
            keyData: absoluteOrdinal(OSType(kAEAll))
        )
    }

    static func insertionEnd(of container: NSAppleEventDescriptor) -> NSAppleEventDescriptor {
        let record = NSAppleEventDescriptor.record()
        record.setDescriptor(container, forKeyword: AEKeyword(keyAEObject))
        record.setDescriptor(.init(enumCode: OSType(kAEEnd)), forKeyword: AEKeyword(keyAEPosition))
        return record.coerce(toDescriptorType: DescType(typeInsertionLoc)) ?? .null()
    }

    private static func objectSpecifier(
        desiredClass: DescType,
        container: NSAppleEventDescriptor?,
        keyForm: DescType,
        keyData: NSAppleEventDescriptor
    ) -> NSAppleEventDescriptor {
        let container = container ?? .null()
        guard let containerDescriptor = container.aeDesc,
              let keyDataDescriptor = keyData.aeDesc else { return .null() }
        var result = AEDesc()
        let status = CreateObjSpecifier(
            desiredClass,
            UnsafeMutablePointer(mutating: containerDescriptor),
            keyForm,
            UnsafeMutablePointer(mutating: keyDataDescriptor),
            false,
            &result
        )
        guard status == noErr else { return .null() }
        return NSAppleEventDescriptor(aeDescNoCopy: &result)
    }

    private static func absoluteOrdinal(_ value: OSType) -> NSAppleEventDescriptor {
        var value = value
        var descriptor = AEDesc()
        let status = AECreateDesc(
            DescType(typeAbsoluteOrdinal),
            &value,
            MemoryLayout<OSType>.size,
            &descriptor
        )
        guard status == noErr else { return .null() }
        return NSAppleEventDescriptor(aeDescNoCopy: &descriptor)
    }
}
