import UIKit

public class CoachmarkManager {
    // ✅ Mark 'shared' as public
    public static let shared = CoachmarkManager()
    
    // ✅ Make the initializer public if needed outside the module
    public init() {}

    // ✅ Mark the function as public
    public func showCoachmarks(fromJson jsonString: String, in parentView: UIView) {
        guard let data = jsonString.data(using: .utf8) else { return }
        
        do {
            let coachmarksData = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
            
            guard let steps = coachmarksData else { return }
            
            for step in steps {
                if let targetId = step["targetViewId"] as? String,
                   let targetView = parentView.viewWithTag(Int(targetId) ?? -1) { // Find view by tag
                    let title = step["title"] as? String ?? ""
                    let message = step["message"] as? String ?? ""

                    let coachmark = CoachmarkView(targetView: targetView, title: title, message: message, frame: parentView.bounds)
                    parentView.addSubview(coachmark)
                }
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
}

