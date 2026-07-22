import OSLog

enum Telemetry {
    static let subsystem = "com.maximedechalendar.ThingsMailman"
    static let processing = Logger(subsystem: subsystem, category: "processing")
    static let automation = Logger(subsystem: subsystem, category: "automation")
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
}
