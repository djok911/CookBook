import Foundation
import UIKit

class ImageService {
    
    /// Сжимает и ресайзит изображение до указанного размера по длинной стороне
    /// - Parameters:
    ///   - imageData: Исходные данные изображения
    ///   - maxDimension: Максимальный размер по длинной стороне (по умолчанию 1600)
    ///   - quality: Качество JPEG сжатия (0.0 - 1.0, по умолчанию 0.8)
    /// - Returns: Сжатые данные изображения в формате JPEG
    static func compressAndResizeImage(_ imageData: Data, maxDimension: CGFloat = 1600, quality: CGFloat = 0.8) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        // Вычисляем новые размеры
        let originalSize = image.size
        let scale: CGFloat
        
        if originalSize.width > originalSize.height {
            scale = maxDimension / originalSize.width
        } else {
            scale = maxDimension / originalSize.height
        }
        
        // Если изображение уже меньше максимального размера, не увеличиваем его
        if scale >= 1.0 {
            return image.jpegData(compressionQuality: quality)
        }
        
        let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        // Создаем новый контекст для ресайза
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        UIGraphicsEndImageContext()
        
        // Сжимаем в JPEG
        return resizedImage.jpegData(compressionQuality: quality)
    }
    
    /// Нормализует теги из строки с запятыми
    /// - Parameter tagsInput: Строка с тегами, разделенными запятыми
    /// - Returns: Массив нормализованных тегов
    static func normalizeTags(from tagsInput: String) -> [String] {
        return tagsInput
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
            .uniqued()
    }
}

// MARK: - Array Extension для удаления дубликатов
private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        return Array(Set(self))
    }
}
