import Foundation
import CryptoKit
import UIKit

class EncryptionService {
    static let shared = EncryptionService()

    private init() {}

    private func getEncryptionKey() throws -> SymmetricKey {
        let keyString = "StatusVault2024Key"
        guard let keyData = keyString.data(using: .utf8) else {
            throw EncryptionError.keyGenerationFailed
        }
        return SymmetricKey(data: SHA256.hash(data: keyData))
    }

    func encryptImage(_ image: UIImage) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw EncryptionError.imageConversionFailed
        }

        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.seal(imageData, using: key)

        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }

        return combined
    }

    func decryptImage(_ encryptedData: Data) throws -> UIImage {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let image = UIImage(data: decryptedData) else {
            throw EncryptionError.imageConversionFailed
        }

        return image
    }

    func saveEncryptedImage(_ image: UIImage, documentID: UUID) throws -> String {
        let encryptedData = try encryptImage(image)
        let filename = "\(documentID.uuidString).enc"

        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw EncryptionError.fileSystemError
        }

        let fileURL = documentsPath.appendingPathComponent(filename)
        try encryptedData.write(to: fileURL)

        return filename
    }

    func loadEncryptedImage(filename: String) throws -> UIImage {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw EncryptionError.fileSystemError
        }

        let fileURL = documentsPath.appendingPathComponent(filename)
        let encryptedData = try Data(contentsOf: fileURL)

        return try decryptImage(encryptedData)
    }
}

enum EncryptionError: Error {
    case keyGenerationFailed
    case imageConversionFailed
    case encryptionFailed
    case decryptionFailed
    case fileSystemError
}
