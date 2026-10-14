import SwiftUI
import ImageIO
struct WatchHome: View {
    @EnvironmentObject private var model: CameraModel
    @State private var query = ""
    @State private var favoritesOnly = false
    var filtered: [Camera] { model.cameras.filter { (!favoritesOnly || model.favorites.contains($0.id)) && (query.isEmpty || $0.searchable.contains(query.folding(options:[.caseInsensitive,.diacriticInsensitive],locale:Locale(identifier:"vi_VN")))) } }
    var body: some View {
        NavigationStack {
            List {
                Toggle("Yêu thích",isOn:$favoritesOnly)
                ForEach(filtered) { camera in
                    NavigationLink { WatchCameraDetail(camera:camera) } label: { Text(camera.name).lineLimit(2) }
                }
                if model.cameras.isEmpty { Text("Mở app iPhone để tải JSON, hoặc nhập URL trong Cài đặt.").font(.caption) }
                NavigationLink("Cài đặt") { WatchSettings() }
            }
            .searchable(text:$query)
            .navigationTitle("TrafficVision")
            .toolbar { Button { Task { await model.refresh() } } label: { Image(systemName:"arrow.clockwise") } }
        }
    }
}
struct WatchSettings: View {
    @EnvironmentObject private var model: CameraModel
    @State private var input = ""
    var body: some View {
        Form {
            TextField("URL JSON HTTPS",text:$input)
            Button("Lưu và tải") { model.saveURL(input); Task { await model.refresh() } }
            Text(model.status).font(.caption)
        }.onAppear { input = model.dataURL }.navigationTitle("Nguồn JSON")
    }
}
struct WatchCameraDetail: View {
    @EnvironmentObject private var model: CameraModel
    let camera: Camera
    @State private var refreshID = UUID()
    var body: some View {
        ScrollView {
            VStack(spacing:8) {
                Text(camera.name).font(.headline)
                if let bytes = model.receivedImages[camera.id],
                   let source = CGImageSourceCreateWithData(bytes as CFData, nil),
                   let image = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                    Image(decorative: image, scale: 1).resizable().scaledToFit()
                } else if let url = camera.imageURL {
                    AsyncImage(url:URL(string:url.absoluteString + (url.query == nil ? "?" : "&") + "r=\(refreshID.uuidString)")) { image in
                        image.resizable().scaledToFit()
                    } placeholder: { ProgressView() }
                } else { Text("Chưa có URL ảnh. Camera video cần snapshot.").font(.caption) }
                Button("Làm mới") { refreshID = UUID() }
                Button(model.favorites.contains(camera.id) ? "♥ Đã lưu" : "♡ Yêu thích") { model.toggleFavorite(camera.id) }
            }.padding(4)
        }
    }
}
