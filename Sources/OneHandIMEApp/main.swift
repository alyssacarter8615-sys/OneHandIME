#if os(macOS)
import Cocoa
import InputMethodKit

@main
struct OneHandIMEApp {
    static func main() {
        let identifier = Bundle.main.bundleIdentifier! + ".IMKServer"
        let server = IMKServer(name: identifier, bundleIdentifier: Bundle.main.bundleIdentifier!)
        _ = server
        NSApplication.shared.run()
    }
}
#endif
