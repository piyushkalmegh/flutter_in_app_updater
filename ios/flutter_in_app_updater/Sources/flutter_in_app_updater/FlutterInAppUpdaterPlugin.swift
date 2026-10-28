import Flutter
import UIKit
import StoreKit

public class FlutterInAppUpdaterPlugin: NSObject, FlutterPlugin, SKStoreProductViewControllerDelegate {
  private var registrar: FlutterPluginRegistrar?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_in_app_updater", binaryMessenger: registrar.messenger())
    let instance = FlutterInAppUpdaterPlugin()
    instance.registrar = registrar
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "updateIos" {
      guard let args = call.arguments as? [String: Any],
            let appIdString = args["appStoreId"] as? String,
            let appId = Int(appIdString) else {
        result.error("INVALID_ID", "App Store ID is missing or invalid", nil)
        return
      }
      presentStoreProductView(appId: appId, result: result)
    } else {
      result.notImplemented()
    }
  }

  private func presentStoreProductView(appId: Int, result: @escaping FlutterResult) {
    let storeController = SKStoreProductViewController()
    storeController.delegate = self

    let parameters = [SKStoreProductParameterITunesItemIdentifierKey: NSNumber(value: appId)]
    storeController.loadProduct(withParameters: parameters) { [weak self] (loaded, error) in
      if let error = error {
        result.error("LOAD_ERROR", error.localizedDescription, nil)
        return
      }
      if loaded {
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
          rootController.present(storeController, animated: true, completion: nil)
          result.success(true)
        } else {
          result.error("NO_VIEW_CONTROLLER", "Unable to find root view controller", nil)
        }
      }
    }
  }

  public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
    viewController.dismiss(animated: true, completion: nil)
  }
}