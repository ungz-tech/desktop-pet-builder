import AppKit

let canvas = NSSize(width: 240, height: 265)
func uptime() -> Double { ProcessInfo.processInfo.systemUptime }
func wallTime() -> Double { Date().timeIntervalSince1970 }

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
struct Sprite {
    let image: NSImage
    let map: NSBitmapImageRep
}
final class PetView: NSView {
    let spec: PetSpec
    weak var app: PetApp?
    var state = PetState()
    var sprites: [String: Sprite] = [:]
    var started: Double?
    var playing = false
    var direction = 1.0
    var time = 0.0
    var pressed = false
    var dragged = false
    var mouseStart = NSPoint.zero
    var windowStart = NSPoint.zero
    var sprite: Sprite? { sprites[state.mood] ?? sprites["calm"] }
    var offset: NSPoint {
        guard let start = started, time >= start, time-start < 3,
              app?.reducedMotion == false else { return .zero }
        let elapsed = time-start, envelope = sin(.pi*elapsed/3)
        if playing { return NSPoint(x: direction*20*envelope, y: abs(sin(elapsed*5))*6*envelope) }
        return spec.motion == "bounce" ? NSPoint(x: 0, y: abs(sin(elapsed*5))*20*envelope)
                                      : NSPoint(x: sin(elapsed*4)*10*envelope, y: 2*envelope)
    }
    var bodyRect: NSRect {
        let pixels = sprite.map { NSSize(width: $0.map.pixelsWide, height: $0.map.pixelsHigh) } ?? NSSize(width: 150, height: 190)
        let factor = min(175/pixels.width, 220/pixels.height)
        let size = NSSize(width: pixels.width*factor, height: pixels.height*factor)
        return NSRect(x: 120-size.width/2+offset.x, y: 15+offset.y, width: size.width, height: size.height)
    }
    init(_ spec: PetSpec) {
        self.spec = spec
        super.init(frame: NSRect(origin: .zero, size: canvas))
        for (mood, file) in spec.images {
            guard let url = Bundle.main.resourceURL?.appendingPathComponent(file),
                  let image = NSImage(contentsOf: url), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            image.size = NSSize(width: cg.width, height: cg.height)
            sprites[mood] = Sprite(image: image, map: NSBitmapImageRep(cgImage: cg))
        }
        setAccessibilityElement(true); setAccessibilityRole(.button)
        setAccessibilityLabel("\(spec.name)，单击互动，双击一起玩，拖动移动，右键菜单")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    func containsBody(_ point: NSPoint) -> Bool {
        let scale = bounds.width/canvas.width
        let point = NSPoint(x: point.x/scale, y: point.y/scale), rect = bodyRect
        guard rect.contains(point) else { return false }
        guard let sprite else { return NSBezierPath(roundedRect: rect, xRadius: 30, yRadius: 30).contains(point) }
        let x = min(sprite.map.pixelsWide-1, Int((point.x-rect.minX)/rect.width*Double(sprite.map.pixelsWide)))
        let y = min(sprite.map.pixelsHigh-1, Int((1-(point.y-rect.minY)/rect.height)*Double(sprite.map.pixelsHigh)))
        return (sprite.map.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.15
    }
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState(); ctx.scaleBy(x: bounds.width/canvas.width, y: bounds.width/canvas.width)
        if let sprite { sprite.image.draw(in: bodyRect, from: .zero, operation: .sourceOver, fraction: 1) }
        else {
            (state.mood == "happy" ? NSColor.systemPink : NSColor.systemTeal).withAlphaComponent(0.8).setFill()
            NSBezierPath(roundedRect: bodyRect, xRadius: 30, yRadius: 30).fill()
            let style = NSMutableParagraphStyle(); style.alignment = .center
            ("\(spec.name)\n素材占位\n\(state.mood)" as NSString).draw(in: bodyRect.insetBy(dx: 8, dy: 65), withAttributes: [.font: NSFont.systemFont(ofSize: 16), .foregroundColor: NSColor.white, .paragraphStyle: style])
        }
        ctx.restoreGState()
    }
    override func mouseDown(with event: NSEvent) {
        pressed = true; dragged = false; started = nil
        mouseStart = NSEvent.mouseLocation; windowStart = window?.frame.origin ?? .zero
    }
    override func mouseDragged(with event: NSEvent) {
        let delta = NSPoint(x: NSEvent.mouseLocation.x-mouseStart.x, y: NSEvent.mouseLocation.y-mouseStart.y)
        if hypot(delta.x, delta.y) > 3 { dragged = true }
        if dragged { window?.setFrameOrigin(NSPoint(x: windowStart.x+delta.x, y: windowStart.y+delta.y)) }
    }
    override func mouseUp(with event: NSEvent) {
        pressed = false
        if dragged { app?.constrainWindows(); app?.save() }
        else if event.clickCount >= 2 { app?.playTogether() }
        else { app?.pat(self) }
    }
    override func rightMouseDown(with event: NSEvent) {
        if let menu = app?.makeMenu() { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }
    override func accessibilityPerformPress() -> Bool { app?.pat(self); return true }
}
final class PetApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let config: Configuration
    let defaults: UserDefaults
    let smoke = CommandLine.arguments.contains("--smoke-test")
    let reducedMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    var clock: BreakClock
    var pets: [PetView] = []
    var panels: [PetPanel] = []
    var status: NSStatusItem!
    var timer: Timer?
    var shown = true
    var scale: Double
    var lastSecond = uptime()
    var lastSave = uptime()
    var reminderPending = false
    var realReminder = false
    var speechUntil = 0.0
    let speech = PetPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 118), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    let message = NSTextField(wrappingLabelWithString: "")
    let restButton = NSButton(title: "好，去走走", target: nil, action: nil)
    let laterButton = NSButton(title: "10 分钟后", target: nil, action: nil)
    init(config: Configuration) {
        self.config = config; scale = config.scale
        let test = CommandLine.arguments.contains("--smoke-test")
        defaults = test ? UserDefaults(suiteName: config.bundle_id+".smoke-tests")! : .standard
        clock = BreakClock(now: wallTime(), interval: config.reminder_minutes*60, enabled: config.reminders_enabled)
        super.init()
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        if smoke { defaults.removePersistentDomain(forName: config.bundle_id+".smoke-tests") }
        scale = min(1, max(0.5, defaults.object(forKey: "scale") as? Double ?? config.scale))
        clock.enabled = defaults.object(forKey: "reminders") as? Bool ?? config.reminders_enabled
        for spec in config.pets {
            let view = PetView(spec); view.app = self
            if let data = defaults.data(forKey: "state."+spec.id), let state = try? JSONDecoder().decode(PetState.self, from: data) { view.state = state; view.state.resume() }
            let panel = PetPanel(contentRect: NSRect(origin: .zero, size: NSSize(width: canvas.width*scale, height: canvas.height*scale)), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = spec.name; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
            panel.level = .floating; panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            panel.contentView = view; pets.append(view); panels.append(panel)
        }
        resetPositions()
        for (pet, panel) in zip(pets, panels) {
            if let position = defaults.string(forKey: "position."+pet.spec.id) { panel.setFrameOrigin(NSPointFromString(position)) }
        }
        constrainWindows(); panels.forEach { $0.orderFrontRegardless() }
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "伙伴"; status.button?.toolTip = config.app_name; status.menu = makeMenu()
        speech.isOpaque = false; speech.backgroundColor = .clear; speech.hasShadow = false; speech.level = .floating
        speech.hidesOnDeactivate = false; speech.isReleasedWhenClosed = false
        speech.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 118)); content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.97).cgColor; content.layer?.cornerRadius = 16
        message.frame = NSRect(x: 16, y: 49, width: 288, height: 53)
        restButton.frame = NSRect(x: 25, y: 12, width: 128, height: 30); laterButton.frame = NSRect(x: 163, y: 12, width: 130, height: 30)
        restButton.target = self; restButton.action = #selector(rest); laterButton.target = self; laterButton.action = #selector(later)
        content.addSubview(message); content.addSubview(restButton); content.addSubview(laterButton); speech.contentView = content
        timer = Timer(timeInterval: reducedMotion ? 0.1 : 1/30, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(woke), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(constrainWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        if smoke { DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { self.smokeCheck(); NSApp.terminate(nil) } }
        else if CommandLine.arguments.contains("--launch-check") {
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                precondition(self.panels.allSatisfy(\.isVisible)); print("PASS: normal preferences and startup path")
                NSApp.terminate(nil)
            }
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { setVisible(true); return true }
    func area(for panel: NSPanel) -> NSRect {
        (NSScreen.screens.first { $0.visibleFrame.contains(NSPoint(x: panel.frame.midX, y: panel.frame.midY)) } ?? NSScreen.main ?? NSScreen.screens[0]).visibleFrame
    }
    @objc func constrainWindows() {
        for panel in panels { panel.setFrameOrigin(clamp(panel.frame.origin, size: panel.frame.size, area: area(for: panel))) }
    }
    @objc func resetPositions() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        for (i, panel) in panels.enumerated() {
            panel.setFrameOrigin(clamp(NSPoint(x: screen.visibleFrame.maxX-Double(i+1)*canvas.width*scale-16, y: screen.visibleFrame.minY+12), size: panel.frame.size, area: screen.visibleFrame))
        }
    }
    func save() {
        for (pet, panel) in zip(pets, panels) {
            defaults.set(NSStringFromPoint(panel.frame.origin), forKey: "position."+pet.spec.id)
            if let data = try? JSONEncoder().encode(pet.state) { defaults.set(data, forKey: "state."+pet.spec.id) }
        }
    }
    @objc func tick() {
        let now = uptime()
        if now-lastSecond >= 1 {
            let elapsed = min(5, max(0, now-lastSecond)); lastSecond = now
            if shown { pets.forEach { $0.state.advance(elapsed) } }
            if now-lastSave >= 30 { save(); lastSave = now }
            if clock.poll(wallTime()) { showReminder(test: false) }
        }
        if speech.isVisible && now >= speechUntil {
            speech.orderOut(nil)
            if reminderPending && realReminder { pets.forEach { $0.state.concern = 90 } }
            reminderPending = false; realReminder = false
        }
        for (pet, panel) in zip(pets, panels) where shown {
            pet.time = now
            if let start = pet.started, now-start >= 3 { pet.started = nil }
            pet.setAccessibilityValue(pet.state.mood); pet.needsDisplay = true
            if !pet.pressed {
                let mouse = NSEvent.mouseLocation
                panel.ignoresMouseEvents = !pet.containsBody(NSPoint(x: mouse.x-panel.frame.minX, y: mouse.y-panel.frame.minY))
            }
        }
    }
    func say(_ line: String, reminder: Bool = false) {
        message.stringValue = line; restButton.isHidden = !reminder; laterButton.isHidden = !reminder
        speechUntil = uptime()+(reminder ? 60 : 5)
        if let anchor = panels.first {
            speech.setFrameOrigin(clamp(NSPoint(x: anchor.frame.midX-160, y: anchor.frame.maxY+8), size: speech.frame.size, area: area(for: anchor)))
        }
        speech.orderFrontRegardless()
    }
    func pat(_ pet: PetView) {
        pets.forEach { $0.started = nil }; pet.state.pat(); pet.started = uptime(); pet.playing = false; save()
        if !reminderPending { say("\(pet.spec.name)：\(config.nickname)，我在这里呢～") }
    }
    @objc func playTogether() {
        guard !reminderPending else { return }
        setVisible(true)
        let center = panels.map { $0.frame.midX }.reduce(0,+)/Double(panels.count)
        for (pet, panel) in zip(pets, panels) { pet.state.pat(); pet.started = uptime(); pet.playing = true; pet.direction = panel.frame.midX <= center ? 1 : -1 }
        save(); say("\(config.nickname)，一起玩一小会儿吧～")
    }
    func showReminder(test: Bool) {
        setVisible(true); pets.forEach { $0.started = nil }
        reminderPending = true; realReminder = !test
        say("\(config.nickname)，看看远处、起来走走吧。我们在这里等你～", reminder: true)
    }
    @objc func rest() {
        reminderPending = false; realReminder = false; clock.restart(wallTime())
        pets.forEach { $0.started = nil; $0.state.resume(); $0.state.unattended = 1200 }
        save(); say("好，\(config.nickname)，慢慢休息，我们等你回来。")
    }
    @objc func later() {
        reminderPending = false; realReminder = false; clock.snooze(wallTime())
        pets.forEach { $0.started = nil; $0.state.concern = 0 }; say("好，十分钟后再提醒你～")
    }
    @objc func woke() {
        clock.restart(wallTime()); lastSecond = uptime(); pets.forEach { $0.state.resume(); $0.started = nil }
        reminderPending = false; realReminder = false; speech.orderOut(nil)
    }
    func setVisible(_ value: Bool) {
        shown = value; pets.forEach { $0.started = nil }
        panels.forEach { value ? $0.orderFrontRegardless() : $0.orderOut(nil) }
        if !value { speech.orderOut(nil); reminderPending = false; realReminder = false }
    }
    @objc func toggleVisible() { setVisible(!shown) }
    @objc func testReminder() { showReminder(test: true) }
    @objc func toggleReminders() {
        clock.enabled.toggle(); clock.restart(wallTime()); defaults.set(clock.enabled, forKey: "reminders")
        if !clock.enabled && reminderPending { reminderPending = false; realReminder = false; speech.orderOut(nil) }
    }
    @objc func changeSize(_ item: NSMenuItem) {
        scale = Double(item.tag)/100; defaults.set(scale, forKey: "scale")
        panels.forEach { $0.setContentSize(NSSize(width: canvas.width*scale, height: canvas.height*scale)) }; constrainWindows()
    }
    @objc func quit() { NSApp.terminate(nil) }
    func makeMenu() -> NSMenu {
        let menu = NSMenu(); menu.delegate = self
        func add(_ title: String, _ selector: Selector?, tag: Int = 0, checked: Bool = false) {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: ""); item.target = self; item.tag = tag; item.state = checked ? .on : .off; menu.addItem(item)
        }
        add(config.app_name, nil)
        for pet in pets { add("\(pet.spec.name) · \(pet.state.mood) · 亲近 \(pet.state.bond)", nil) }
        add("一起玩", #selector(playTogether)); add("提醒休息", #selector(toggleReminders), checked: clock.enabled)
        add("试试提醒", #selector(testReminder))
        for size in [50,65,80,100] { add("大小 \(size)%", #selector(changeSize(_:)), tag: size, checked: abs(scale-Double(size)/100)<0.001) }
        add("回到屏幕角落", #selector(resetPositions)); add(shown ? "隐藏伙伴" : "显示伙伴", #selector(toggleVisible)); add("退出", #selector(quit)); return menu
    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        let fresh = makeMenu(); menu.removeAllItems()
        for item in fresh.items { fresh.removeItem(item); menu.addItem(item) }
    }
    func menuWillOpen(_ menu: NSMenu) { pets.forEach { $0.started = nil } }
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate(); save()
        if smoke { defaults.removePersistentDomain(forName: config.bundle_id+".smoke-tests") }
    }
    func smokeCheck() {
        timer?.invalidate()
        precondition(Bundle.main.bundleIdentifier == config.bundle_id && panels.count == config.pets.count && panels.allSatisfy(\.isVisible))
        pat(pets[0]); precondition(pets[0].state.mood == "happy")
        if pets.count > 1 { precondition(pets[1].state.mood == "calm") }
        showReminder(test: true); let due = clock.nextDue; playTogether()
        precondition(reminderPending && clock.nextDue == due); later()
        precondition(abs(clock.nextDue-wallTime()-600)<2)
        showReminder(test: true); speechUntil = 0; tick(); precondition(pets.allSatisfy { $0.state.concern == 0 })
        showReminder(test: false); speechUntil = 0; tick(); precondition(pets.allSatisfy { $0.state.concern == 90 })
        rest(); setVisible(false); precondition(panels.allSatisfy { !$0.isVisible }); setVisible(true)
        let size = NSMenuItem(); size.tag = 50; changeSize(size); precondition(panels.allSatisfy { abs($0.frame.width-120)<0.01 })
        for pet in pets {
            pet.time = uptime(); precondition(!pet.containsBody(.zero))
            if pet.sprite == nil { precondition(pet.containsBody(NSPoint(x: 60, y: 60))) }
            pet.started = 0; pet.playing = true
            for time in [0.0, 0.5, 1.2, 2.9] {
                pet.time = time
                let bitmap = pet.bitmapImageRepForCachingDisplay(in: pet.bounds)!
                pet.cacheDisplay(in: pet.bounds, to: bitmap)
                let sx = Double(bitmap.pixelsWide)/pet.bounds.width, sy = Double(bitmap.pixelsHigh)/pet.bounds.height
                var opaqueSamples = 0
                for y in stride(from: 2, to: bitmap.pixelsHigh-2, by: 7) {
                    for x in stride(from: 2, to: bitmap.pixelsWide-2, by: 7) where (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.98 {
                        opaqueSamples += 1
                        precondition(pet.containsBody(NSPoint(x: (Double(x)+0.5)/sx, y: pet.bounds.height-(Double(y)+0.5)/sy)))
                    }
                }
                precondition(opaqueSamples > 10)
                for y in 0..<bitmap.pixelsHigh {
                    precondition((bitmap.colorAt(x: 0, y: y)?.alphaComponent ?? 0) < 0.5)
                    precondition((bitmap.colorAt(x: bitmap.pixelsWide-1, y: y)?.alphaComponent ?? 0) < 0.5)
                }
                for x in 0..<bitmap.pixelsWide {
                    precondition((bitmap.colorAt(x: x, y: 0)?.alphaComponent ?? 0) < 0.5)
                    precondition((bitmap.colorAt(x: x, y: bitmap.pixelsHigh-1)?.alphaComponent ?? 0) < 0.5)
                }
            }
            pet.started = nil
        }
        if let index = CommandLine.arguments.firstIndex(of: "--qa-dir"), index+1 < CommandLine.arguments.count {
            let folder = URL(fileURLWithPath: CommandLine.arguments[index+1]); try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for pet in pets {
                let bitmap = pet.bitmapImageRepForCachingDisplay(in: pet.bounds)!
                pet.cacheDisplay(in: pet.bounds, to: bitmap)
                try! bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(pet.spec.id+".png"))
            }
        }
        save(); precondition(defaults.data(forKey: "state."+pets[0].spec.id) != nil)
        print("PASS: native windows, independent clicks, reminder priority/test immunity, snooze, hide/show, sizing, animated pixel hit tests, unclipped edges and persistence")
    }
}

if CommandLine.arguments.contains("--self-test") { runModelTests() }
else {
    do {
        let url = Bundle.main.url(forResource: "config", withExtension: "json")!
        let config = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: url))
        let app = NSApplication.shared; app.setActivationPolicy(.accessory)
        let delegate = PetApp(config: config); app.delegate = delegate; app.run()
    } catch { fputs("Unable to load config: \(error)\n", stderr); exit(1) }
}
