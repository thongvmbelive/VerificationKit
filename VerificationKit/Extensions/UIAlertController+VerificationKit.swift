import UIKit

internal extension UIAlertController {
    class func show(_ error: NSError?) {
        let alert = UIAlertController(
            title: "Error".localized,
            message: error?.localizedDescription,
            preferredStyle: .alert)
        let action = UIAlertAction(title: "OK".localized, style: .default, handler: nil)
        alert.addAction(action)

        DispatchQueue.main.async(execute: {
            UIViewController.topViewController()?.present(alert, animated: true, completion: nil)
        })
    }

    class func showError(message: String) {
        let alert = UIAlertController(
            title: "Error".localized,
            message: message,
            preferredStyle: .alert)
        let action = UIAlertAction(title: "OK".localized, style: .default, handler: nil)
        alert.addAction(action)

        DispatchQueue.main.async(execute: {
            UIViewController.topViewController()?.present(alert, animated: true, completion: nil)
        })
    }
}
