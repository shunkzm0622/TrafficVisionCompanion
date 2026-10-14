import SwiftUI
struct PhoneHome: View {
    @EnvironmentObject private var model: CameraModel
    @State private var query = ""
    @State private var onlyFavorites = false
    @State private var editingURL = ""
    private var filtered: [Camera] { model.cameras.filter { (!onlyFavorites || model.favorites.contains($0.id)) && (query.isEmpty || $0.searchable.contains(query.folding(options:[.diacriticInsensitive,.caseInsensitive],locale:Locale(identifier:"vi_VN")))) } }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("https://.../cameras.json", text: $editingURL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    Button("Lưu URL và tải camera") { model.saveURL(editingURL); Task { await model.refresh() } }
                    Text(model.status).font(.footnote).foregroundStyle(.secondary)
                } header: { Text("Nguồn GitHub JSON") }
                Section {
                    Toggle("Chỉ camera yêu thích", isOn: $onlyFavorites)
                    ForEach(filtered) { camera in
                        NavigationLink { PhoneCameraDetail(camera: camera) } label: {
                            VStack(alignment: .leading,spacing: 3) {
                                Text(camera.name)
                                Text(camera.source ?? camera.id).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: { Text("Camera (\(filtered.count))") }
            }
            .searchable(text: $query,prompt:"Tìm tên đường hoặc ID")
            .navigationTitle("TrafficVision")
            .toolbar { Button { Task { await model.refresh() } } label: { Image(systemName:"arrow.clockwise") } }
            .refreshable { await model.refresh() }
            .onAppear { editingURL = model.dataURL }
        }
    }
}
struct PhoneCameraDetail: View {
    @EnvironmentObject private var model: CameraModel
    let camera: Camera
    @State private var refreshID = UUID()
    var body: some View {
        ScrollView {
            VStack(spacing:16) {
                if let url = camera.imageURL {
                    AsyncImage(url: URL(string: url.absoluteString + (url.query == nil ? "?" : "&") + "r=\(refreshID.uuidString)")) { image in
                        image.resizable().scaledToFit()
                    } placeholder: { ProgressView() }
                    .frame(maxWidth:.infinity,minHeight:180)
                    Button("Làm mới ảnh") { refreshID = UUID() }
                    Button("Gửi ảnh sang Apple Watch") { Task { await model.sendImage(camera) } }
                } else { ContentUnavailableView("Không có ảnh tĩnh",systemImage:"video.slash",description:Text("Nếu camera chỉ có stream/video, cần dịch vụ snapshot HTTPS.")) }
                Button(model.favorites.contains(camera.id) ? "Bỏ yêu thích" : "Thêm yêu thích") { model.toggleFavorite(camera.id) }
                Text(model.status).font(.footnote).foregroundStyle(.secondary)
                Text(camera.id).font(.caption2).textSelection(.enabled)
            }.padding()
        }.navigationTitle(camera.name).navigationBarTitleDisplayMode(.inline)
    }
}
