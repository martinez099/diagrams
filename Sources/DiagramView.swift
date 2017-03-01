import Cocoa

public protocol Drawable {
    func draw(ctx: CGContext, bounds: CGRect)
}

public class DiagramView : NSView {

    let drawable: Drawable

    public init(frame frameRect: NSRect, drawable: Drawable) {
        self.drawable = drawable
        super.init(frame: frameRect)
    }

    required public init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override public func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current() else { return }
        drawable.draw(ctx: context.cgContext, bounds: self.bounds)
    }

    public func imageRepresentation() -> NSImage? {
        let wantedLayer = self.wantsLayer;
        self.wantsLayer = true;
        let image = NSImage(size: self.bounds.size)
        image.lockFocus()
        guard let context = NSGraphicsContext.current() else { return nil }
        self.layer?.render(in: context.cgContext)
        image.unlockFocus()
        self.wantsLayer = wantedLayer
        return image
    }

    public func saveAsImage(path: String) throws {
        let image = imageRepresentation()!
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let pngData = rep.representation(using: NSBitmapImageFileType.PNG, properties: [:])!
        try pngData.write(to: URL(fileURLWithPath: path), options: .atomic)
        Swift.print("Saved image as \(path)")
    }
}
