//
//  File.swift
//  CTTemplates
//
//  Created by Karthik Iyer on 25/02/25.
//

import UIKit

public class CoachmarViewHelper: UIView {
    
    var coachmarksData: [[String: Any]] = []
    var currentCoachmarkIndex: Int = 0
    public var onNext: (() -> Void)?
    public var onSkip: (() -> Void)?

    public init(jsonData: Data, frame: CGRect) {
        super.init(frame: frame)
        parseJSON(jsonData)
        showNextCoachmark()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func parseJSON(_ jsonData: Data) {
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
                coachmarksData = jsonArray
            }
        } catch {
            print("❌ JSON Parsing Error: \(error)")
        }
    }

    func showNextCoachmark() {
        if currentCoachmarkIndex >= coachmarksData.count {
            return
        }

        let step = coachmarksData[currentCoachmarkIndex]
        
        guard let targetView = step["targetView"] as? UIView,
              let title = step["title"] as? String,
              let message = step["message"] as? String else { return }

        let coachmark = CoachmarkView(
            targetView: targetView,
            title: title,
            message: message,
            currentIndex: currentCoachmarkIndex + 1,
            totalSteps: coachmarksData.count,
            frame: self.bounds
        )

        coachmark.onNext = {
            self.currentCoachmarkIndex += 1
            self.showNextCoachmark()
        }

        coachmark.onSkip = {
            self.currentCoachmarkIndex = self.coachmarksData.count
            self.removeFromSuperview()
        }

        self.addSubview(coachmark)
    }
}
