import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("无法创建绘图上下文")
}

context.setAllowsAntialiasing(true)
let outerRect = NSRect(x: 56, y: 56, width: 912, height: 912)
let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: 205, yRadius: 205)
let gradient = NSGradient(
    starting: NSColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1),
    ending: NSColor(red: 0.025, green: 0.03, blue: 0.045, alpha: 1)
)!
gradient.draw(in: outerPath, angle: -55)

let cyan = NSColor(red: 0.18, green: 0.88, blue: 1.0, alpha: 1)
let magenta = NSColor(red: 1.0, green: 0.20, blue: 0.58, alpha: 1)

let sandbox = NSBezierPath()
sandbox.move(to: NSPoint(x: 512, y: 818))
sandbox.line(to: NSPoint(x: 748, y: 682))
sandbox.line(to: NSPoint(x: 704, y: 382))
sandbox.line(to: NSPoint(x: 512, y: 242))
sandbox.line(to: NSPoint(x: 320, y: 382))
sandbox.line(to: NSPoint(x: 276, y: 682))
sandbox.close()
NSColor(red: 0.08, green: 0.16, blue: 0.20, alpha: 0.72).setFill()
sandbox.fill()
cyan.withAlphaComponent(0.22).setStroke()
sandbox.lineWidth = 62
sandbox.lineJoinStyle = .round
sandbox.stroke()
cyan.setStroke()
sandbox.lineWidth = 24
sandbox.stroke()

let prompt = NSBezierPath()
prompt.move(to: NSPoint(x: 390, y: 610))
prompt.line(to: NSPoint(x: 500, y: 520))
prompt.line(to: NSPoint(x: 390, y: 430))
prompt.lineCapStyle = .round
prompt.lineJoinStyle = .round
prompt.lineWidth = 42
cyan.setStroke()
prompt.stroke()

let cursor = NSBezierPath()
cursor.move(to: NSPoint(x: 548, y: 432))
cursor.line(to: NSPoint(x: 662, y: 432))
cursor.lineCapStyle = .round
cursor.lineWidth = 38
NSColor.white.setStroke()
cursor.stroke()

let statusNode = NSBezierPath(ovalIn: NSRect(x: 694, y: 630, width: 72, height: 72))
magenta.withAlphaComponent(0.25).setFill()
statusNode.fill()
let statusCore = NSBezierPath(ovalIn: NSRect(x: 710, y: 646, width: 40, height: 40))
magenta.setFill()
statusCore.fill()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("无法编码 App 图标")
}

try png.write(to: outputURL, options: .atomic)
