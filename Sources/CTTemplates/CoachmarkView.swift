import UIKit

@MainActor
public class CoachmarkManager {
    
    public static let shared = CoachmarkManager()
    private var coachmarksData: [[String: Any]] = []
    private var currentCoachmarkIndex: Int = 0
    private var parentView: UIView?
    
    private init() {}
    
    public func showCoachmarks(fromJson json: Any, in parentView: UIView) {
        self.parentView = parentView
        self.currentCoachmarkIndex = 0
        
        var jsonDict: [String: Any] = [:]
        
        if let arrayJson = json as? [[String: Any]], let firstItem = arrayJson.first {
            jsonDict = firstItem
        } else if let dictJson = json as? [String: Any] {
            jsonDict = dictJson
        } else {
            return
        }
        
        if let ndJsonString = jsonDict["nd_json"] as? String,
           let ndJsonData = ndJsonString.data(using: .utf8),
           let parsedNdJson = try? JSONSerialization.jsonObject(with: ndJsonData) as? [String: Any] {
            jsonDict = parsedNdJson
        } else if let ndJsonDict = jsonDict["nd_json"] as? [String: Any] {
            jsonDict = ndJsonDict
        }
        
        let coachmarkCount: Int
        if let count = jsonDict["nd_coachmarks_count"] as? Int {
            coachmarkCount = count
        } else if let countString = jsonDict["nd_coachmarks_count"] as? String, let countInt = Int(countString) {
            coachmarkCount = countInt
        } else {
            return
        }
        
        var steps: [[String: Any]] = []
        for index in 1...coachmarkCount {
            let idKey = "nd_view\(index)_id"
            let titleKey = "nd_view\(index)_title"
            let subtitleKey = "nd_view\(index)_subtitle"
            
            if let targetId = jsonDict[idKey] as? String,
               let title = jsonDict[titleKey] as? String,
               let message = jsonDict[subtitleKey] as? String
            {
                steps.append([
                    "targetViewId": targetId,
                    "title": title,
                    "message": message
                ])
            } else {
                print("Skipping step \(index): Missing id/title/subtitle in JSON")
            }
        }
        
        self.coachmarksData = steps
        
        let positiveButtonText = jsonDict["nd_positive_button_text"] as? String ?? "Next"
        let skipButtonText = jsonDict["nd_skip_button_text"] as? String ?? "Skip"
        let positiveButtonBackgroundColor = jsonDict["nd_positive_button_background_color"] as? String ?? "#E83938"
        let skipButtonBackgroundColor = jsonDict["nd_skip_button_background_color"] as? String ?? "#FFFFFF"
        let positiveButtonTextColor = jsonDict["nd_positive_button_text_color"] as? String ?? "#FFFFFF"
        let skipButtonTextColor = jsonDict["nd_skip_button_text_color"] as? String ?? "#000000"
        let finalButtonText = jsonDict["nd_final_positive_button_text"] as? String ?? "Ready to Explore"
        
        print("positiveButtonText1: \(positiveButtonText)")
        
        showNextCoachmark(positiveButtonText: positiveButtonText, skipButtonText: skipButtonText, positiveButtonBackgroundColor: positiveButtonBackgroundColor, skipButtonBackgroundColor: skipButtonBackgroundColor, positiveButtonTextColor: positiveButtonTextColor, skipButtonTextColor: skipButtonTextColor, finalButtonText: finalButtonText)
    }
    
    private func showNextCoachmark(positiveButtonText: String, skipButtonText: String, positiveButtonBackgroundColor: String, skipButtonBackgroundColor:String, positiveButtonTextColor: String, skipButtonTextColor: String, finalButtonText: String) {
        guard currentCoachmarkIndex < coachmarksData.count, let parentView = self.parentView else {
            return
        }
        
        let step = coachmarksData[currentCoachmarkIndex]
        if let targetId = step["targetViewId"] as? String,
           let targetView = findViewByIdentifier(targetId, in: parentView) {
            let title = step["title"] as? String ?? ""
            let message = step["message"] as? String ?? ""
            let coachmark = CoachmarkView(
                targetView: targetView,
                title: title,
                message: message,
                currentIndex: currentCoachmarkIndex + 1,
                totalSteps: coachmarksData.count,
                frame: parentView.bounds,
                positiveButtonText: positiveButtonText,
                skipButtonText: skipButtonText,
                positiveButtonBackgroundColor: positiveButtonBackgroundColor,
                skipButtonBackgroundColor: skipButtonBackgroundColor,
                positiveButtonTextColor: positiveButtonTextColor,
                skipButtonTextColor: skipButtonTextColor,
                finalButtonText: finalButtonText
            )
            
            coachmark.onNext = { [weak self, weak coachmark] in
                coachmark?.removeFromSuperview()
                self?.currentCoachmarkIndex += 1
                self?.showNextCoachmark(positiveButtonText: positiveButtonText, skipButtonText: skipButtonText, positiveButtonBackgroundColor: positiveButtonBackgroundColor, skipButtonBackgroundColor: skipButtonBackgroundColor, positiveButtonTextColor: positiveButtonTextColor, skipButtonTextColor: skipButtonTextColor, finalButtonText: finalButtonText)
            }
            
            coachmark.onSkip = { [weak self, weak coachmark] in
                coachmark?.removeFromSuperview()
                self?.currentCoachmarkIndex = self?.coachmarksData.count ?? 0
            }
            
            parentView.addSubview(coachmark)
        } else {
            currentCoachmarkIndex += 1
            showNextCoachmark(positiveButtonText: positiveButtonText, skipButtonText: skipButtonText, positiveButtonBackgroundColor: positiveButtonBackgroundColor, skipButtonBackgroundColor: skipButtonBackgroundColor, positiveButtonTextColor: positiveButtonTextColor, skipButtonTextColor: skipButtonTextColor, finalButtonText: finalButtonText)
        }
    }
    
    private func findViewByIdentifier(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier {
            return view
        }
        for subview in view.subviews {
            if let found = findViewByIdentifier(identifier, in: subview) {
                return found
            }
        }
        return nil
    }
}
