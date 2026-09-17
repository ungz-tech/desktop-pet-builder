import Foundation

struct PetSpec: Codable {
    let id: String
    let name: String
    let motion: String
    let images: [String: String]
}
struct Configuration: Codable {
    let app_name: String
    let bundle_id: String
    let nickname: String
    let scale: Double
    let reminder_minutes: Double
    let reminders_enabled: Bool
    let pets: [PetSpec]
}
struct PetState: Codable {
    var bond = 20
    var unattended = 0.0
    var happy = 0.0
    var concern = 0.0
    var cooldown = 0.0
    var mood: String { concern > 0 ? "concerned" : happy > 0 ? "happy" : unattended >= 1200 ? "sleepy" : "calm" }
    mutating func advance(_ seconds: Double) {
        guard seconds.isFinite && seconds > 0 else { return }
        unattended += seconds; happy = max(0, happy-seconds); concern = max(0, concern-seconds); cooldown = max(0, cooldown-seconds)
    }
    mutating func pat() {
        unattended = 0; happy = 180; concern = 0
        if cooldown == 0 { bond = min(100, bond+1); cooldown = 30 }
    }
    mutating func resume() { unattended = 0; happy = 0; concern = 0; cooldown = 0 }
}
struct BreakClock {
    let interval: Double
    var enabled: Bool
    var nextDue: Double
    init(now: Double, interval: Double, enabled: Bool) {
        self.interval = interval; self.enabled = enabled; nextDue = now+interval
    }
    mutating func poll(_ now: Double) -> Bool {
        guard enabled && now >= nextDue else { return false }
        nextDue = now+interval; return true
    }
    mutating func restart(_ now: Double) { nextDue = now+interval }
    mutating func snooze(_ now: Double) { nextDue = now+600 }
}
func clamp(_ point: CGPoint, size: CGSize, area: CGRect) -> CGPoint {
    CGPoint(x: min(max(area.minX, point.x), max(area.minX, area.maxX-size.width)),
            y: min(max(area.minY, point.y), max(area.minY, area.maxY-size.height)))
}
func runModelTests() {
    var a = PetState(), b = PetState()
    a.advance(1200); precondition(a.mood == "sleepy" && b.mood == "calm")
    a.pat(); let bond = a.bond; a.pat(); precondition(a.bond == bond && a.mood == "happy")
    b.concern = 90; b.advance(90); precondition(b.mood == "calm")
    var restored = try! JSONDecoder().decode(PetState.self, from: JSONEncoder().encode(a))
    restored.resume(); precondition(restored.bond == bond && restored.mood == "calm")
    var clock = BreakClock(now: 0, interval: 3600, enabled: true)
    precondition(!clock.poll(3599) && clock.poll(3600) && !clock.poll(3600))
    clock.snooze(3610); precondition(!clock.poll(4209) && clock.poll(4210))
    clock.enabled = false; precondition(!clock.poll(99999))
    clock.enabled = true; clock.restart(100000); precondition(!clock.poll(100001))
    precondition(clamp(CGPoint(x: -9999, y: -10), size: CGSize(width: 156, height: 172), area: CGRect(x: -1400, y: 40, width: 1400, height: 860)) == CGPoint(x: -1400, y: 40))
    print("PASS: independent moods, affection cooldown, persistence, recovery, reminder boundaries/snooze/pause and negative-screen bounds")
}
