//import UIKit
//
//@MainActor
//public class CoachmarkManager {
//    public static let shared = CoachmarkManager()
//    
//    // Stores the parsed coachmark steps from JSON.
//    private var coachmarksData: [[String: Any]] = []
//    private var currentCoachmarkIndex: Int = 0
//    private var parentView: UIView?
//    
//    // Public initializer is not needed because we use the shared instance.
//    private init() {}
//    
//    // Pass JSON as a string along with the parent view in which to display the coachmarks.
//    public func showCoachmarks(fromJson jsonString: String, in parentView: UIView) {
//        self.parentView = parentView
//        guard let data = jsonString.data(using: .utf8) else { return }
//        
//        do {
//            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
//                self.coachmarksData = jsonArray
//                self.currentCoachmarkIndex = 0
//                // Show the first coachmark.
//                self.showNextCoachmark()
//            }
//        } catch {
//            print("Error parsing JSON: \(error)")
//        }
//    }
//    
//    private func showNextCoachmark() {
//        guard currentCoachmarkIndex < coachmarksData.count, let parentView = self.parentView else { return }
//        
//        let step = coachmarksData[currentCoachmarkIndex]
//        // Find the target view using the accessibilityIdentifier (dynamic)
//        if let targetId = step["targetViewId"] as? String,
//           let targetView = findViewByIdentifier(targetId, in: parentView) {
//            
//            let title = step["title"] as? String ?? ""
//            let message = step["message"] as? String ?? ""
//            
//            // Create the coachmark view with required parameters.
//            let coachmark = CoachmarkView(
//                targetView: targetView,
//                title: title,
//                message: message,
//                currentIndex: currentCoachmarkIndex + 1,
//                totalSteps: coachmarksData.count,
//                frame: parentView.bounds
//            )
//            
//            // When user taps "Next", remove the current coachmark and show the next one.
//            coachmark.onNext = { [weak self, weak coachmark] in
//                coachmark?.removeFromSuperview()
//                self?.currentCoachmarkIndex += 1
//                self?.showNextCoachmark()
//            }
//            // When user taps "Skip", remove the coachmark and stop the tour.
//            coachmark.onSkip = { [weak self, weak coachmark] in
//                coachmark?.removeFromSuperview()
//                self?.currentCoachmarkIndex = self?.coachmarksData.count ?? 0
//            }
//            
//            parentView.addSubview(coachmark)
//        } else {
//            // If target view not found, skip to next coachmark.
//            currentCoachmarkIndex += 1
//            showNextCoachmark()
//        }
//    }
//    
//    // Recursively search for a view with the given accessibilityIdentifier.
//    private func findViewByIdentifier(_ identifier: String, in view: UIView) -> UIView? {
//        if view.accessibilityIdentifier == identifier {
//            return view
//        }
//        for subview in view.subviews {
//            if let found = findViewByIdentifier(identifier, in: subview) {
//                return found
//            }
//        }
//        return nil
//    }
//}
//


import UIKit

@MainActor
public class CoachmarkManager {
    public static let shared = CoachmarkManager()
    
    private var coachmarksData: [[String: Any]] = []
    private var currentCoachmarkIndex: Int = 0
    private weak var parentView: UIView?
    
    private init() {}

    public func showCoachmarks(fromJson jsonString: String, in parentView: UIView) {
        self.parentView = parentView
        guard let parsedJson = parseAndFlattenJson(jsonString) else { return }
        
        self.coachmarksData = parsedJson
        self.currentCoachmarkIndex = 0
        showNextCoachmark()
    }
    
    private func parseAndFlattenJson(_ jsonString: String) -> [[String: Any]]? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            guard let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("Invalid JSON format")
                return nil
            }

            var customKv = jsonDict["custom_kv"] as? [String: Any] ?? [:]

            if let ndJsonString = customKv["nd_json"] as? String,
               let ndJsonData = ndJsonString.data(using: .utf8),
               let parsedNdJson = try JSONSerialization.jsonObject(with: ndJsonData, options: []) as? [String: Any] {
                
                for (key, value) in parsedNdJson {
                    customKv[key] = value
                }
            }

            print("Merged customKv:", customKv)

            guard let coachmarkCount = customKv["nd_coachmarks_count"] as? Int else {
                print("Error: 'nd_coachmarks_count' missing or invalid")
                return nil
            }

            var parsedCoachmarks: [[String: Any]] = []
            for i in 1...coachmarkCount {
                let titleKey = "nd_view\(i)_title"
                let subTitleKey = "nd_view\(i)_subtitle"
                let viewIdKey = "nd_view\(i)_id"

                guard let viewId = customKv[viewIdKey] as? String, !viewId.isEmpty else {
                    print("Error: '\(viewIdKey)' missing or empty")
                    continue
                }

                parsedCoachmarks.append([
                    "targetViewId": viewId,
                    "title": customKv[titleKey] as? String ?? "Default Title",
                    "message": customKv[subTitleKey] as? String ?? "Default Subtitle",
                    "isLastItem": (i == coachmarkCount),
                    "positiveButtonText": (i == coachmarkCount) ? customKv["nd_final_positive_button_text"] as? String ?? "Ready to Explore" :
                        customKv["nd_positive_button_text"] as? String ?? "Next",
                    "skipButtonText": (i == coachmarkCount) ? nil : customKv["nd_skip_button_text"] as? String ?? "Skip",
                    "positiveButtonTextColor": customKv["nd_positive_button_text_color"] as? String ?? "#FFFFFF",
                    "positiveButtonBGColor": customKv["nd_positive_button_background_color"] as? String ?? "#E83938",
                    "skipButtonBGColor": customKv["nd_skip_button_background_color"] as? String ?? "#FFFFFF",
                    "skipButtonTextColor": customKv["nd_skip_button_text_color"] as? String ?? "#000000"
                ])
            }
            
            return parsedCoachmarks
        } catch {
            print("Error parsing JSON: \(error)")
            return nil
        }
    }

    private func showNextCoachmark() {
        guard currentCoachmarkIndex < coachmarksData.count, let parentView = parentView else { return }

        let step = coachmarksData[currentCoachmarkIndex]
        if let targetId = step["targetViewId"] as? String,
           let targetView = findViewByIdentifier(targetId, in: parentView) {

            let coachmark = CoachmarkView(
                targetView: targetView,
                title: step["title"] as? String ?? "",
                message: step["message"] as? String ?? "",
                currentIndex: currentCoachmarkIndex + 1,
                totalSteps: coachmarksData.count,
                frame: parentView.bounds
            )

            coachmark.setButtonStyles(
                positiveText: step["positiveButtonText"] as? String ?? "Next",
                skipText: step["skipButtonText"] as? String,
                positiveColor: step["positiveButtonTextColor"] as? String ?? "#FFFFFF",
                positiveBGColor: step["positiveButtonBGColor"] as? String ?? "#E83938",
                skipColor: step["skipButtonTextColor"] as? String ?? "#000000",
                skipBGColor: step["skipButtonBGColor"] as? String ?? "#FFFFFF"
            )

            coachmark.onNext = { [weak self, weak coachmark] in
                coachmark?.removeFromSuperview()
                self?.currentCoachmarkIndex += 1
                self?.showNextCoachmark()
            }

            coachmark.onSkip = { [weak self, weak coachmark] in
                coachmark?.removeFromSuperview()
                self?.currentCoachmarkIndex = self?.coachmarksData.count ?? 0
            }

            parentView.addSubview(coachmark)
        } else {
            print("Skipping coachmark: Target view not found for \(step["targetViewId"] ?? "Unknown")")
            currentCoachmarkIndex += 1
            showNextCoachmark()
        }
    }

    private func findViewByIdentifier(_ identifier: String, in view: UIView) -> UIView? {
        return view.subviews.first(where: { $0.accessibilityIdentifier == identifier }) ??
               view.subviews.lazy.compactMap { findViewByIdentifier(identifier, in: $0) }.first
    }
}
