import Foundation

struct Camera: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var latitude: Double?
    var longitude: Double?
    var imageURL: URL?
    var videoURL: URL?
    var source: String?
    var searchable: String { (name + " " + id + " " + (source ?? "")).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")) }
}

enum CameraParser {
    static func parse(_ data: Data) throws -> [Camera] {
        let root = try JSONSerialization.jsonObject(with: data)
        let entries: [Any]
        if let a = root as? [Any] { entries = a }
        else if let d = root as? [String: Any] { entries = (d["cameras"] as? [Any]) ?? (d["data"] as? [Any]) ?? (d["features"] as? [Any]) ?? (d["items"] as? [Any]) ?? [] }
        else { entries = [] }
        var ids = Set<String>()
        return entries.enumerated().compactMap { n, item -> Camera? in
            guard let d = item as? [String: Any] else { return nil }
            let p = d["properties"] as? [String: Any] ?? d
            let coords = (d["geometry"] as? [String: Any])?["coordinates"] as? [Any]
            let id = string(p, ["id","camId","cameraId","camera_id","code","_id"]) ?? string(d,["id"]) ?? "camera-\(n)"
            guard ids.insert(id).inserted else { return nil }
            let name = string(p,["name","location","camLocation","camera_name","title","address","description"]) ?? "Camera \(id)"
            return Camera(id: id, name: name,
                latitude: number(p,["latitude","lat","y"]) ?? (coords?.count ?? 0 > 1 ? numberValue(coords?[1]) : nil),
                longitude: number(p,["longitude","lng","lon","long","x"]) ?? (coords?.count ?? 0 > 0 ? numberValue(coords?[0]) : nil),
                imageURL: url(p,["imageURL","imageUrl","image_url","snapshot","snapshotUrl","snapshot_url","thumbnail","image"]),
                videoURL: url(p,["videoURL","videoUrl","video_url","streamUrl","stream_url","stream","url","hls","m3u8"]),
                source: string(p,["source","provider","district","area"]))
        }
    }
    private static func string(_ d: [String: Any], _ keys: [String]) -> String? {
        for k in keys { if let s = d[k] as? String, !s.isEmpty { return s }; if let n = d[k] as? NSNumber { return n.stringValue } }; return nil
    }
    private static func numberValue(_ x: Any?) -> Double? { if let n = x as? NSNumber { return n.doubleValue }; if let s = x as? String { return Double(s) }; return nil }
    private static func number(_ d: [String: Any], _ keys: [String]) -> Double? { for k in keys { if let v = numberValue(d[k]) { return v } }; return nil }
    private static func url(_ d: [String: Any], _ keys: [String]) -> URL? {
        guard let s = string(d,keys), let u = URL(string:s), u.scheme?.lowercased() == "https" else { return nil }; return u
    }
}
