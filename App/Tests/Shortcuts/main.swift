import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    print((condition ? "PASS " : "FAIL ") + name)
    if !condition { failures += 1 }
}

check(ShortcutURL.run(name: "   ") == nil, "empty shortcut name is rejected")

if let url = ShortcutURL.run(name: "Honda Music Play Pause") {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let items = components?.queryItems ?? []
    check(components?.scheme == "shortcuts", "uses public Shortcuts scheme")
    check(components?.host == "x-callback-url", "uses documented callback host")
    check(components?.path == "/run-shortcut", "uses documented run-shortcut path")
    check(items.first(where: { $0.name == "name" })?.value == "Honda Music Play Pause", "encodes shortcut name with spaces")
    check(items.first(where: { $0.name == "x-success" })?.value == ShortcutURL.completionURL, "returns to companion app")
    check(items.first(where: { $0.name == "x-error" })?.value == ShortcutURL.completionURL, "returns on error")
} else {
    check(false, "URL generation")
}

if let url = ShortcutURL.run(name: "Zażółć & 🏍️") {
    let name = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "name" }?.value
    check(name == "Zażółć & 🏍️", "round trips unicode and reserved characters")
} else {
    check(false, "unicode URL generation")
}

exit(failures == 0 ? 0 : 1)
