import Flutter
import UIKit
import GoogleSignIn  // GoogleSignIn 모듈 임포트

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 클라이언트 ID 설정 (GoogleSignIn 초기화)
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(
      clientID: "103432441156-v010qrvgibrim15me9icquslhuc3pbf4.apps.googleusercontent.com"
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // URL 핸들링 메서드 추가 (iOS 9 이상)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}