import SwiftUI
@main struct TrafficVisioniPhoneApp: App {
    @StateObject private var model = CameraModel()
    var body: some Scene { WindowGroup { PhoneHome().environmentObject(model) } }
}
