import Cocoa
import ServiceManagement
import AppKit

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSResponder, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    static var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    static var timesOptionPressed = 0
    static var keyboardOff = false
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
}


extension AppDelegate {

    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        print("hm")
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        
        AppDelegate.statusItem.menu = statusMenu
        
        let passiveIcon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        passiveIcon?.isTemplate = true // best for dark mode
        AppDelegate.statusItem.image = passiveIcon
        
        let launcherAppId = "sh.jona.catproofLauncher"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty

        SMLoginItemSetEnabled(launcherAppId as CFString, true)

        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher,
                                                         object: Bundle.main.bundleIdentifier!)
        }
        

        
        
     
        
        func eOneCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
            
            
            if [.flagsChanged, .keyDown].contains(type) {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                
                if keyCode == 59 {
                    AppDelegate.timesOptionPressed += 1
                    if AppDelegate.timesOptionPressed == 6 { // Toggle keyboard
                        AppDelegate.keyboardOff = !AppDelegate.keyboardOff
                        AppDelegate.timesOptionPressed = 0
                        if AppDelegate.keyboardOff {
                            AppDelegate.statusItem.image = NSImage(named: NSImage.Name(rawValue: "activeIcon"))
                        } else {
                            AppDelegate.statusItem.image = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
                        }
                    }
                } else {
                    AppDelegate.timesOptionPressed = 0
                }
                if AppDelegate.keyboardOff {
                    return nil
                }
                
            }
            return Unmanaged.passRetained(event)
        }
        func eTwoCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
            
            
            
            if AppDelegate.keyboardOff {
                event.location = CGPoint(x: NSScreen.main!.frame.width , y: NSScreen.main!.frame.height )
            }
            
            
            return Unmanaged.passRetained(event)
        }
        
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let eventMask2 = (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(eventMask),
                                               callback: eOneCallback,
                                               userInfo: nil) else {
                                                exit(1)
        
        }
        guard let eventTap2 = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(eventMask2),
                                               callback: eTwoCallback,
                                               userInfo: nil) else {
                                                exit(1)
                                                
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        let runLoopSource2 = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap2, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource2, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CGEvent.tapEnable(tap: eventTap2, enable: true)
        CFRunLoopRun()
        
    }

}

