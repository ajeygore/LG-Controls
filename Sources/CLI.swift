import Foundation

let args = CommandLine.arguments
let manager = DDCManager.shared()
let displays = manager.getDisplays()

guard let target = displays.first(where: { $0.isExternal }) else {
    print("❌ Error: No external DDC monitor detected.")
    exit(1)
}

if args.count <= 1 || args[1] == "status" || args[1] == "get" {
    print("🖥️  Monitor: \(target.name) (Index: \(target.index))")
    let b = manager.getLuminance(target.index)
    let c = manager.getContrast(target.index)
    let v = manager.getVolume(target.index)
    let muted = manager.getMute(target.index)
    
    print("☀️  Brightness: \(b)%")
    print("🌓  Contrast:   \(c)%")
    print("🔊  Volume:     \(v)% \(muted ? "(MUTED)" : "")")
    exit(0)
}

let command = args[1].lowercased()

switch command {
case "b", "brightness", "lum", "luminance":
    if args.count >= 3, let val = Int(args[2]) {
        let clamped = max(0, min(100, val))
        let ok = manager.setLuminance(clamped, forDisplay: target.index)
        if ok {
            print("✅ Brightness set to \(clamped)%")
        } else {
            print("❌ Failed to set brightness")
            exit(1)
        }
    } else {
        let b = manager.getLuminance(target.index)
        print("\(b)")
    }
    
case "c", "contrast":
    if args.count >= 3, let val = Int(args[2]) {
        let clamped = max(0, min(100, val))
        let ok = manager.setContrast(clamped, forDisplay: target.index)
        if ok {
            print("✅ Contrast set to \(clamped)%")
        } else {
            print("❌ Failed to set contrast")
            exit(1)
        }
    } else {
        let c = manager.getContrast(target.index)
        print("\(c)")
    }
    
case "v", "volume":
    if args.count >= 3, let val = Int(args[2]) {
        let clamped = max(0, min(100, val))
        let ok = manager.setVolume(clamped, forDisplay: target.index)
        if ok {
            print("✅ Volume set to \(clamped)%")
        } else {
            print("❌ Failed to set volume")
            exit(1)
        }
    } else {
        let v = manager.getVolume(target.index)
        print("\(v)")
    }
    
case "mute":
    let ok = manager.setMute(true, forDisplay: target.index)
    print(ok ? "🔇 Muted" : "❌ Failed to mute")
    
case "unmute":
    let ok = manager.setMute(false, forDisplay: target.index)
    print(ok ? "🔊 Unmuted" : "❌ Failed to unmute")
    
case "preset":
    guard args.count >= 3 else {
        print("Usage: lg-control preset [night|read|day|cinema]")
        exit(1)
    }
    let preset = args[2].lowercased()
    switch preset {
    case "night":
        _ = manager.setLuminance(20, forDisplay: target.index)
        _ = manager.setContrast(60, forDisplay: target.index)
        print("🌙 Night profile applied (Brightness 20%, Contrast 60%)")
    case "read":
        _ = manager.setLuminance(40, forDisplay: target.index)
        _ = manager.setContrast(65, forDisplay: target.index)
        print("📖 Read profile applied (Brightness 40%, Contrast 65%)")
    case "day":
        _ = manager.setLuminance(75, forDisplay: target.index)
        _ = manager.setContrast(70, forDisplay: target.index)
        print("☀️ Day profile applied (Brightness 75%, Contrast 70%)")
    case "cinema":
        _ = manager.setLuminance(100, forDisplay: target.index)
        _ = manager.setContrast(80, forDisplay: target.index)
        print("🎬 Cinema profile applied (Brightness 100%, Contrast 80%)")
    default:
        print("Unknown preset '\(preset)'. Choose from: night, read, day, cinema")
        exit(1)
    }
    
case "help", "-h", "--help":
    print("""
    LG Monitor Control CLI
    Usage:
      lg-control [status]             Show current brightness, contrast, volume
      lg-control brightness [0-100]   Get or set brightness
      lg-control contrast [0-100]     Get or set contrast
      lg-control volume [0-100]       Get or set volume
      lg-control mute                 Mute audio
      lg-control unmute               Unmute audio
      lg-control preset <name>        Apply preset (night, read, day, cinema)
    """)
    
default:
    print("Unknown command: \(command). Run 'lg-control help' for usage.")
    exit(1)
}
