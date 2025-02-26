import UIKit

@MainActor // ✅ Ensures all UI-related work happens on the main thread
public class CoachmarkManager {
    // ✅ Making 'shared' concurrency-safe
    public static let shared = CoachmarkManager()

    private init() {} // ✅ Prevents direct instantiation outside the class

    var currentCoachmarkIndex = 0
    var coachmarksData: [[String: Any]] = []

    public func showCoachmarks(fromJson jsonString: String, in parentView: UIView) {
        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            coachmarksData = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? []
            currentCoachmarkIndex = 0
            showNextCoachmark(in: parentView)
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }

    // ✅ Show next coachmark one at a time
    public func showNextCoachmark(in parentView: UIView) {
        if currentCoachmarkIndex >= coachmarksData.count { return }  // Stop if all steps are done

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
                frame: parentView.bounds
            )

            parentView.addSubview(coachmark)

            // ✅ Wait for user action before proceeding to next step
            coachmark.onDismiss = { [weak self] in
                coachmark.removeFromSuperview()
                self?.currentCoachmarkIndex += 1
                self?.showNextCoachmark(in: parentView)
            }
        }
    }


}
