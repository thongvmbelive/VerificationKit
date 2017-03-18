import UIKit

internal extension UIViewController {
    class func topViewController() -> UIViewController? {
        var topController = UIApplication.shared.keyWindow?.rootViewController

        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }
}
