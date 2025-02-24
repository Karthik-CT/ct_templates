import UIKit

class DottedLineView: UIView {
    
    private var startPoint: CGPoint
    private var endPoint: CGPoint
    private let yellowDotLayer = CAShapeLayer()
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init(frame: CGRect.zero)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(6)
        
        let dashPattern: [CGFloat] = [6, 3] // 6pt line, 3pt gap
        context.setLineDash(phase: 0, lengths: dashPattern)
        
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawYellowDot()
    }
    
    private func drawYellowDot() {
        yellowDotLayer.removeFromSuperlayer() // Remove any existing dots
        
        let circleRadius: CGFloat = 15
        let targetPoint = shouldPlaceDotAtStartPoint() ? startPoint : endPoint
        
        let circlePath = UIBezierPath(ovalIn: CGRect(
            x: targetPoint.x - circleRadius / 2,
            y: targetPoint.y - circleRadius / 2,
            width: circleRadius,
            height: circleRadius
        ))
        
        yellowDotLayer.fillColor = UIColor(hex: "#FFD700").cgColor
        yellowDotLayer.path = circlePath.cgPath
        
        self.layer.addSublayer(yellowDotLayer)
    }
    
    private func shouldPlaceDotAtStartPoint() -> Bool {
        guard let superview = self.superview else { return false }
        let screenHeight = UIScreen.main.bounds.height
        let bottomThreshold = screenHeight * 0.75 // Adjusted threshold dynamically
        return endPoint.y > bottomThreshold
    }

}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
