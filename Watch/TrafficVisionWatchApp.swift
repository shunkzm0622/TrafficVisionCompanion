import SwiftUI
@main struct TrafficVisionWatchApp: App {
    @StateObject private var model = CameraModel()
    var body: some Scene { WindowGroup { WatchHome().environmentObject(model) } }
}
