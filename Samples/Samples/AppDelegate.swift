import AWSCore
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:REGION_TYPE, identityPoolId:IDENTITY_POOL_ID)
        let configuration = AWSServiceConfiguration(region: REGION_TYPE, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        return true
    }
}
