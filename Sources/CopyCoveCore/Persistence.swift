import AppKit

public protocol PersistenceStore: AnyObject {
    func loadItems() -> [ClipItem]
    func saveItems(_ items: [ClipItem])
    func saveImage(data: Data, fileName: String)
    func imageData(fileName: String) -> Data?
    func deleteImage(fileName: String)
}
