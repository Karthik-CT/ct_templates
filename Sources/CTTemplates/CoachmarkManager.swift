import UIKit

@MainActor
public class CoachmarkManager {
    public static let shared = CoachmarkManager()

    // Stores the parsed coachmark steps from JSON.
    private var coachmarksData: [[String: Any]] = []
    private var currentCoachmarkIndex: Int = 0
    private var parentView: UIView?

    // Public initializer is not needed because we use the shared instance.
    private init() {}

    // Pass JSON as a string along with the parent view in which to display the coachmarks.
    public func showCoachmarks(fromJson jsonString: String, in parentView: UIView) {
        self.parentView = parentView
        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                self.coachmarksData = jsonArray
                self.currentCoachmarkIndex = 0
                // Show the first coachmark.
                self.showNextCoachmark()
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }

    private func showNextCoachmark() {
        guard currentCoachmarkIndex < coachmarksData.count, let parentView = self.parentView else { return }

        let step = coachmarksData[currentCoachmarkIndex]
        // Find the target view using the accessibilityIdentifier (dynamic)
        if let targetId = step["targetViewId"] as? String,
           let targetView = findViewByIdentifier(targetId, in: parentView) {

            let title = step["title"] as? String ?? ""
            let message = step["message"] as? String ?? ""

            // Create the coachmark view with required parameters.
            let coachmark = CoachmarkView(
                targetView: targetView,
                title: title,
                message: message,
                currentIndex: currentCoachmarkIndex + 1,
                totalSteps: coachmarksData.count,
                frame: parentView.bounds
            )

            // When user taps "Next", remove the current coachmark and show the next one.
            coachmark.onNext = { [weak self, weak coachmark] in
                coachmark?.removeFromSuperview()
                self?.currentCoachmarkIndex += 1
                self?.showNextCoachmark()
            }
            // When user taps "Skip", remove the coachmark and stop the tour.
            coachmark.onSkip = { [weak self, weak coachmark] in
                coachmark?.removeFromSuperview()
                self?.currentCoachmarkIndex = self?.coachmarksData.count ?? 0
            }

            parentView.addSubview(coachmark)
        } else {
            // If target view not found, skip to next coachmark.
            currentCoachmarkIndex += 1
            showNextCoachmark()
        }
    }

    // Recursively search for a view with the given accessibilityIdentifier.
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
