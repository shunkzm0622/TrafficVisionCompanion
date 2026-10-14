import Foundation
import WatchConnectivity

@MainActor final class CameraModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var cameras: [Camera] = []
    @Published var favorites: Set<String> = []
    @Published var dataURL: String = UserDefaults.standard.string(forKey: "jsonURL") ?? ""
    @Published var status = "Chưa tải dữ liệu"
    @Published var isLoading = false
    #if os(watchOS)
    @Published var receivedImages: [String: Data] = [:]
    #endif
    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    override init() {
        super.init()
        favorites = Set(UserDefaults.standard.stringArray(forKey: "favorites") ?? [])
        if let saved = UserDefaults.standard.data(forKey: "cameraCache"), let decoded = try? JSONDecoder().decode([Camera].self, from: saved) { cameras = decoded }
        session?.delegate = self
        session?.activate()
    }
    func saveURL(_ url: String) { dataURL = url.trimmingCharacters(in: .whitespacesAndNewlines); UserDefaults.standard.set(dataURL, forKey:"jsonURL") }
    func toggleFavorite(_ id: String) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
        UserDefaults.standard.set(Array(favorites),forKey:"favorites")
        sendState()
    }
    func refresh() async {
        guard let url = URL(string: dataURL), url.scheme?.lowercased() == "https" else { status = "Nhập URL HTTPS của file JSON"; return }
        isLoading = true; defer { isLoading = false }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode), data.count < 10_000_000 else { status = "Lỗi HTTP hoặc dữ liệu quá lớn"; return }
            let decoded = try CameraParser.parse(data)
            guard !decoded.isEmpty else { status = "Không tìm thấy camera trong JSON"; return }
            cameras = decoded
            UserDefaults.standard.set(try JSONEncoder().encode(decoded),forKey:"cameraCache")
            status = "Đã tải \(decoded.count) camera"
            sendState()
        } catch { status = "Lỗi tải JSON: \(error.localizedDescription)" }
    }
    func sendState() {
        guard let session = session, session.activationState == .activated else { return }
        if let data = try? JSONEncoder().encode(cameras), data.count < 4_000_000 {
            let payload: [String: Any] = ["cameras": data, "favorites": Array(favorites), "jsonURL": dataURL]
            try? session.updateApplicationContext(payload)
        }
    }
    #if os(iOS)
    func sendImage(_ camera: Camera) async {
        guard let url = camera.imageURL, let session = session, session.activationState == .activated else { status = "Camera không có URL ảnh HTTPS"; return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let r = response as? HTTPURLResponse, (200...299).contains(r.statusCode),
                  data.count < 1_500_000, (r.mimeType ?? "").lowercased().hasPrefix("image/") else { status = "Ảnh không hợp lệ hoặc quá lớn"; return }
            if session.isReachable {
                session.sendMessage(["imageId":camera.id, "image":data], replyHandler:nil, errorHandler:{ _ in })
                status = "Đã gửi ảnh (nếu Watch đang kết nối)"
            } else { status = "Mở ứng dụng trên Apple Watch để nhận ảnh" }
        } catch { status = "Không tải được ảnh: \(error.localizedDescription)" }
    }
    #endif
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.sendState() }
    }
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let data = applicationContext["cameras"] as? Data, let decoded = try? JSONDecoder().decode([Camera].self,from:data) {
                self.cameras = decoded
                UserDefaults.standard.set(data,forKey:"cameraCache")
            }
            if let favs = applicationContext["favorites"] as? [String] {
                self.favorites = Set(favs)
                UserDefaults.standard.set(favs,forKey:"favorites")
            }
            if let url = applicationContext["jsonURL"] as? String, !url.isEmpty { self.saveURL(url) }
            self.status = "Đã đồng bộ từ thiết bị ghép đôi"
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        #if os(watchOS)
        Task { @MainActor in
            if let id = message["imageId"] as? String, let data = message["image"] as? Data { self.receivedImages[id] = data }
        }
        #endif
    }
}
