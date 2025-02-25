import UIKit

@MainActor // ✅ Ensures all UI-related work happens on the main thread
public class CoachmarkManager {
    // ✅ Making 'shared' concurrency-safe
    public static let shared = CoachmarkManager()

    private init() {} // ✅ Prevents direct instantiation outside the class

    public func showCoachmarks(fromJson jsonString: String, in parentView: UIView) {
        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            let coachmarksData = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
            guard let steps = coachmarksData else { return }

            var currentIndex = 0

            for step in steps {
                if let targetId = step["targetViewId"] as? String,
                   let targetView = findViewByIdentifier(targetId, in: parentView) {  // ✅ Find view dynamically

                    let title = step["title"] as? String ?? ""
                    let message = step["message"] as? String ?? ""

                    let coachmark = CoachmarkView(
                        targetView: targetView,
                        title: title,
                        message: message,
                        currentIndex: currentIndex + 1,
                        totalSteps: steps.count,
                        frame: parentView.bounds
                    )

                    parentView.addSubview(coachmark)
                    currentIndex += 1
                }
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }

    // ✅ Helper function to find a view by accessibility identifier
    private func findViewByIdentifier(_ identifier: String, in view: UIView) -> UIView? {
        for subview in view.subviews {
            if subview.accessibilityIdentifier == identifier {
                return subview
            }
            if let foundView = findViewByIdentifier(identifier, in: subview) {
                return foundView
            }
        }
        return nil
    }

}
