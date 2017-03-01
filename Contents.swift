//: # Diagram - noun: a drawing used to explain something that is difficult to understand

//: Stefan Wehr (wehr@cp-med.com), 24.2.2017, BOB, Berlin

/*:

Funktionale Programmierung ist (oft) **deklarativ**. Für das Zeichnen von Diagrammen bedeutet das:

* Um ein Diagramm zu zeichnen, spezifiziert der Programmiere **was** gezeichnet werden soll.
* Der Programmierer muss sich nicht darum kümmern **wie** das Zeichnen geschieht.

Im folgenden stellen wir die API und die Implementierung einer einfachen Bibliothek zum Zeichnen von
Diagrammen vor. Der Code basiert auf dem Buch *Functional Programming in Swift* 
(Chris Eidhof, Florian Kugler, Wouter Swierstra; 2014) sowie auf der 
Haskell-Bibliothek [diagrams](http://projects.haskell.org/diagrams/) von Brent Yorgey.
*/

import Cocoa
import PlaygroundSupport

//: ## Definition der Datentypen

enum Shape {
    case Ellipse
    case Rectangle
}

indirect enum Diagram {
    case Primitive(CGSize, Shape)
    case Below(Diagram, Diagram)
    case Annotated(Attribute, Diagram)
}

enum Attribute {
    case FillColor(NSColor)
    case Alignment(Align)
}

typealias Align = CGPoint

//: Bemerkung: in funktionalen Sprache heißen solche `enum`s auch **algebraische Datentypen** oder **Summentypen**.

//: Ein ersten Beispiel:

let sz = CGSize(width: 1, height: 1)
let blueSquare = Diagram.Annotated(Attribute.FillColor(NSColor.blue),
    Diagram.Primitive(sz, Shape.Rectangle))

//: ### Smarte Konstruktoren (Kombinatoren)

//: Primitive Formen

func square(side: CGFloat) -> Diagram {
    return Diagram.Primitive(CGSize(width:side, height:side), Shape.Rectangle)
}

func circle(radius: CGFloat) -> Diagram {
    return Diagram.Primitive(CGSize(width:2*radius, height:2*radius), Shape.Ellipse)
}

func rectangle(width: CGFloat, height: CGFloat) -> Diagram {
    return Diagram.Primitive(CGSize(width:width, height:height), Shape.Rectangle)
}

//: Farben und Alignment

// let blueSquare = square(1).fill(NSColor.blue).alignLeft()

extension Diagram {
    func fill(color: NSColor) -> Diagram {
        return .Annotated(Attribute.FillColor(color), self)
    }
    func align(x: CGFloat, y: CGFloat) -> Diagram {
        return .Annotated(Attribute.Alignment(CGPoint(x:x, y:y)), self)
    }
    func alignRight() -> Diagram {
        return align(x: 1, y:0.5)
    }
    func alignTop() -> Diagram {
        return align(x: 0.5, y:1)
    }
    func alignBottom() -> Diagram {
        return align(x: 0.5, y:0)
    }
}

//: Operatoren zur Platzierung untereinander


infix operator ---: AdditionPrecedence
func --- (top: Diagram, bottom: Diagram) -> Diagram {
    return Diagram.Below(top, bottom)
}

//: ### Mehr Beispiele

//: ![sampleDiagram1a](diag1.png)
//: ![sampleDiagram1b](diag2.png)
//: ![sampleDiagram2](diag3.png)

let redSquare = square(side: 2).fill(color: .red)
let greenCircle = circle(radius: 0.5).fill(color: .green)
let sampleDiagram1 = greenCircle --- redSquare

//: ## Funktionen über algebraische Datentypen

//: Kochrezept: Fallunterscheidung

extension Diagram {
    func size() -> CGSize {
        switch self {
        case .Primitive(let sz, _):
            return sz
        case .Below(let up, let down):
            let us = up.size()
            let ds = down.size()
            return CGSize(width: max(us.width, ds.width), height: us.height + ds.height)
        case .Annotated(_, let d):
            return d.size()
        }
    }
}

/*:

## Diskussion: Algebraische Datentype vs. Klassen

* Funktionale Sprachen: algebraischen Datentypen
  - Hinzufügen neuer Funktionen: einfach
  - Hinzufügen neuer Fälle: schwierig
* OO-Sprachen: Klassen
  - Hinzufügen neuer Funktionen: schwierig
  - Hinzufügen neuer Fälle: einfach

*/

//: ## Zeichnen

extension Diagram : Drawable {
    func draw(ctx: CGContext, bounds: CGRect) {
        switch (self) {
        case .Primitive(let sz, let shape):
            let frame = fit(size: sz, align: alignCenter, bounds: bounds)
            switch (shape) {
            case .Ellipse:
                ctx.fillEllipse(in: frame)
            case .Rectangle:
                ctx.fill(frame)
            }
        case .Below(let top, let bottom):
            let (topBounds, bottomBounds) = splitVertical(top: top.size(), bottom: bottom.size(), bounds: bounds)
            top.draw(ctx: ctx, bounds:topBounds)
            bottom.draw(ctx: ctx, bounds:bottomBounds)
        case .Annotated(.FillColor(let color), let diagram):
            ctx.saveGState()
            color.set()
            diagram.draw(ctx: ctx, bounds:bounds)
            ctx.restoreGState()
        case .Annotated(.Alignment(let align), let diagram):
            let newBounds = fit(size: diagram.size(), align: align, bounds: bounds)
            diagram.draw(ctx: ctx, bounds:newBounds)
        }
    }
}

// testAuxiliaries()

//: # Beispiele
func viewDiagram(diagram: Diagram) {
    let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    let view = DiagramView(frame:frame, drawable:diagram)
    PlaygroundPage.current.liveView = view
}
viewDiagram(diagram: sampleDiagram1)

/*
viewDiagram(diagram: blueSquare)
viewDiagram(diagram: redSquare)
viewDiagram(diagram: greenCircle)
viewDiagram(diagram: blueSquare ||| greenCircle)
viewDiagram(diagram: redSquare --- blueSquare)
 */
/*
viewDiagram(diagram:
    redSquare --- square(side: 0.1).fill(color: .green)
    --- blueSquare)
 */
/*
viewDiagram(diagram: redSquare --- blueSquare.alignRight())
viewDiagram(diagram: (redSquare --- blueSquare.alignRight()).alignRight())
viewDiagram(diagram: sampleDiagram1a)
viewDiagram(diagram: sampleDiagram1b)
viewDiagram(diagram: sampleDiagram2)
*/
print("finished")
