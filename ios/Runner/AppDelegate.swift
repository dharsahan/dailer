import Flutter
import UIKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, CXProviderDelegate {

    private let METHOD_CHANNEL = "com.example.flutter_dialer/methods"
    private let EVENT_CHANNEL = "com.example.flutter_dialer/events"

    private var eventSink: FlutterEventSink?
    private var provider: CXProvider?
    private var callController: CXCallController?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Setup CallKit
        let configuration = CXProviderConfiguration(localizedName: "Flutter Dialer")
        configuration.supportsVideo = false
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.phoneNumber]

        provider = CXProvider(configuration: configuration)
        provider?.setDelegate(self, queue: nil)

        callController = CXCallController()

        // Setup Flutter Channels
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

        let methodChannel = FlutterMethodChannel(name: METHOD_CHANNEL,
                                                 binaryMessenger: controller.binaryMessenger)

        methodChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "makeCall" {
                guard let args = call.arguments as? [String: Any],
                      let number = args["number"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Number is missing", details: nil))
                    return
                }
                self.startCall(handle: number)
                result(nil)
            } else if call.method == "setDefaultDialer" {
                 // iOS doesn't have "Default Dialer" concept like Android in the same way,
                 // but we can check permissions or just return success as it's often a no-op or handled via Settings.
                 // For this task, we'll just return success.
                 result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        let eventChannel = FlutterEventChannel(name: EVENT_CHANNEL,
                                               binaryMessenger: controller.binaryMessenger)
        eventChannel.setStreamHandler(CallStreamHandler(appDelegate: self))

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func setEventSink(sink: FlutterEventSink?) {
        self.eventSink = sink
    }

    // MARK: - CallKit Actions

    func startCall(handle: String) {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        let transaction = CXTransaction(action: startCallAction)

        callController?.request(transaction, completion: { error in
            if let error = error {
                print("Error starting call: \(error)")
            } else {
                 print("Call started successfully")
            }
        })
    }

    // MARK: - CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {
        // Stop all audio/calls
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        // Signal to the system that the call has started
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())

        // Notify Flutter
        sendCallEvent(state: 1, number: action.handle.value) // 1 = DIALING

        action.fulfill()

        // Simulate connecting/connected for demo purposes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            self.sendCallEvent(state: 4, number: action.handle.value) // 4 = ACTIVE
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // Notify Flutter
        // We don't easily have the number here without tracking UUIDs, sending "Unknown" or tracking it separately.
        // For simplicity, we send state.
        sendCallEvent(state: 7, number: "") // 7 = DISCONNECTED
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
         action.fulfill()
         sendCallEvent(state: 4, number: "") // 4 = ACTIVE
    }

    private func sendCallEvent(state: Int, number: String) {
        if let sink = eventSink {
            sink(["state": state, "number": number])
        }
    }
}

class CallStreamHandler: NSObject, FlutterStreamHandler {
    weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        appDelegate?.setEventSink(sink: events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        appDelegate?.setEventSink(sink: nil)
        return nil
    }
}
