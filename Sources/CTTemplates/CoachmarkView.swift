import UIKit

public class CoachmarkView: UIView {
    
    var targetView: UIView
    var title: String
    var message: String
    var currentIndex: Int
    var totalSteps: Int
    var onNext: (() -> Void)?
    var onSkip: (() -> Void)?
    
    public let stepIndicatorLabel = UILabel()
    
    public override init(targetView: UIView, title: String, message: String, currentIndex: Int, totalSteps: Int, frame: CGRect) {
        self.targetView = targetView
        self.title = title
        self.message = message
        self.currentIndex = currentIndex
        self.totalSteps = totalSteps
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        let path = UIBezierPath(rect: self.bounds)
        let targetFrame = targetView.convert(targetView.bounds, to: self)
        let cutoutPath = UIBezierPath(roundedRect: targetFrame.insetBy(dx: -8, dy: -8), cornerRadius: 10)
        path.append(cutoutPath)
        path.usesEvenOddFillRule = true
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        self.layer.mask = maskLayer
        
        let screenHeight = UIScreen.main.bounds.height
        let isTargetNearBottom = targetFrame.maxY + 200 > screenHeight // Adjusted threshold

        let tooltipYPosition: CGFloat
        let arrowStartY: CGFloat
        let arrowEndY: CGFloat
        let gap: CGFloat = 40 // **Increased gap between target and tooltip**

        if isTargetNearBottom {
            // Show tooltip above target
            tooltipYPosition = targetFrame.minY - 165 - gap // Increased gap
            arrowStartY = tooltipYPosition + 10
            arrowEndY = targetFrame.midY - 5
        } else {
            // Show tooltip below target
            tooltipYPosition = targetFrame.maxY + gap // Increased gap
            arrowStartY = targetFrame.maxY + 5
            arrowEndY = tooltipYPosition - 5
        }

        let tooltipView = createTooltipView(atY: tooltipYPosition)
        self.addSubview(tooltipView)

        configureStepIndicator(in: tooltipView)

//        let startX = targetFrame.midX
//        let endX = tooltipView.frame.midX
//        let commonX = (startX + endX) / 2
//
//        let startPoint = CGPoint(x: commonX, y: arrowStartY)
//        let endPoint = CGPoint(x: commonX, y: arrowEndY)
//
//        let dottedLineView = DottedLineView(startPoint: startPoint, endPoint: endPoint)
//        dottedLineView.frame = self.bounds
//        dottedLineView.isUserInteractionEnabled = false
//
//        self.addSubview(dottedLineView)
        
        let startX = targetFrame.midX
        let endX = tooltipView.frame.midX
        let commonX = (startX + endX) / 2

        let startPoint: CGPoint
        let endPoint: CGPoint

        if isTargetNearBottom {
            startPoint = CGPoint(x: commonX, y: tooltipView.frame.maxY - 5) // Start from tooltip bottom
            endPoint = CGPoint(x: commonX, y: targetFrame.midY) // End at target
        } else {
            startPoint = CGPoint(x: commonX, y: targetFrame.maxY + 5) // Start from target bottom
            endPoint = CGPoint(x: commonX, y: tooltipView.frame.minY) // End at tooltip top
        }

        let dottedLineView = DottedLineView(startPoint: startPoint, endPoint: endPoint)
        dottedLineView.frame = self.bounds
        dottedLineView.isUserInteractionEnabled = false
        self.addSubview(dottedLineView)
        
    }


    // Updated Tooltip Positioning
    private func createTooltipView(atY yPosition: CGFloat) -> UIView {
        let tooltipView = UIView(frame: CGRect(x: 20, y: yPosition, width: self.frame.width - 40, height: 145))
        tooltipView.backgroundColor = .white
        tooltipView.layer.cornerRadius = 12
        tooltipView.layer.shadowColor = UIColor.black.cgColor
        tooltipView.layer.shadowOpacity = 0.2
        tooltipView.layer.shadowOffset = CGSize(width: 0, height: 2)
        tooltipView.layer.shadowRadius = 4
        
        let titleLabel = UILabel(frame: CGRect(x: 16, y: 12, width: tooltipView.frame.width - 32, height: 22))
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        tooltipView.addSubview(titleLabel)
        
        let messageLabel = UILabel(frame: CGRect(x: 16, y: 38, width: tooltipView.frame.width - 32, height: 40))
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0
        tooltipView.addSubview(messageLabel)
        
        let buttonsContainer = UIStackView(frame: CGRect(x: 16, y: 95, width: tooltipView.frame.width - 32, height: 35))
        buttonsContainer.axis = .horizontal
        buttonsContainer.alignment = .fill
        buttonsContainer.distribution = .fillEqually
        buttonsContainer.spacing = 10
        
        let skipButton = UIButton(type: .system)
        var skipConfig = UIButton.Configuration.filled()
        skipConfig.baseBackgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        skipConfig.baseForegroundColor = .black
        skipConfig.cornerStyle = .medium
        skipConfig.title = "Skip"
        skipButton.configuration = skipConfig
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        
        let nextButton = UIButton(type: .system)
        nextButton.setTitle(currentIndex == totalSteps ? "Ready to Explore" : "Next", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = .red
        nextButton.layer.cornerRadius = 5
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        buttonsContainer.addArrangedSubview(skipButton)
        buttonsContainer.addArrangedSubview(nextButton)
        tooltipView.addSubview(buttonsContainer)
        
        if currentIndex == totalSteps {
            skipButton.alpha = 0
            skipButton.isUserInteractionEnabled = false
        } else {
            skipButton.alpha = 1
            skipButton.isUserInteractionEnabled = true
        }
        
        return tooltipView
    }

    
    private func configureStepIndicator(in tooltipView: UIView) {
        stepIndicatorLabel.text = "\(currentIndex)/\(totalSteps)"
        stepIndicatorLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        stepIndicatorLabel.textColor = UIColor.gray
        stepIndicatorLabel.textAlignment = .right
        stepIndicatorLabel.backgroundColor = .clear
        stepIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to the tooltip view
        tooltipView.addSubview(stepIndicatorLabel)
        
        // Constraints to position at the top-right corner of the tooltip view
        NSLayoutConstraint.activate([
            stepIndicatorLabel.topAnchor.constraint(equalTo: tooltipView.topAnchor, constant: 8),
            stepIndicatorLabel.trailingAnchor.constraint(equalTo: tooltipView.trailingAnchor, constant: -12)
        ])
    }
    
    @objc private func skipTapped() {
        onSkip?()
        self.removeFromSuperview()
    }
    
    @objc private func nextTapped() {
        onNext?()
        self.removeFromSuperview()
    }
}
