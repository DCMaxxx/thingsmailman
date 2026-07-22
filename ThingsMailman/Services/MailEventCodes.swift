import Carbon

enum MailEventCodes {
    static let core: AEEventClass = fourChar("core")
    static let mail: AEEventClass = fourChar("emal")
    static let message: AEEventClass = fourChar("emsg")
    static let getData: AEEventID = fourChar("getd")
    static let create: AEEventID = fourChar("crel")
    static let move: AEEventID = fourChar("move")
    static let delete: AEEventID = fourChar("delo")
    static let forward: AEEventID = fourChar("fwms")
    static let send: AEEventID = fourChar("send")

    static let messageClass: DescType = fourChar("mssg")
    static let mailboxClass: DescType = fourChar("mbxp")
    static let accountClass: DescType = fourChar("mact")
    static let messageViewerClass: DescType = fourChar("mvwr")
    static let recipientClass: DescType = fourChar("trcp")
    static let selectionProperty: DescType = fourChar("slct")
    static let selectedMessagesProperty: DescType = fourChar("smgs")
    static let subjectProperty: DescType = fourChar("subj")
    static let mailboxProperty: DescType = fourChar("mbxp")
    static let accountProperty: DescType = fourChar("mact")
    static let identifierProperty: DescType = fourChar("ID  ")
    static let nameProperty: DescType = fourChar("pnam")
    static let containerProperty: DescType = fourChar("mbxc")
    static let addressProperty: DescType = fourChar("radd")
    static let openingWindowParameter: AEKeyword = fourChar("ropw")
    static let insertHereParameter: AEKeyword = fourChar("insh")

    static func fourChar(_ value: StaticString) -> UInt32 {
        var result: UInt32 = 0
        value.withUTF8Buffer { buffer in
            for byte in buffer.prefix(4) { result = (result << 8) | UInt32(byte) }
        }
        return result
    }
}
