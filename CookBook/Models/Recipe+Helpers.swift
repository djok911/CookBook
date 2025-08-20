import Foundation
import CoreData

extension Recipe {
    
    /// Парсит tagsRaw по запятым, триммит пробелы, приводит к lowercased, удаляет дубликаты и пустые
    var tags: [String] {
        get {
            guard let tagsRaw = tagsRaw, !tagsRaw.isEmpty else { return [] }
            
            return tagsRaw
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { $0.lowercased() }
                .filter { !$0.isEmpty }
                .uniqued()
        }
    }
    
    /// Собирает теги обратно в tagsRaw (сортирует по алфавиту)
    /// Сохраняет в формате ",tag," для избежания частичных совпадений при поиске
    func setTags(_ tags: [String]) {
        let sortedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()
        
        // Сохраняем в формате ",tag," для избежания частичных совпадений
        tagsRaw = ", " + sortedTags.joined(separator: ", ") + ","
    }
    
    /// Мигрирует существующие теги в новый формат ",tag,"
    func migrateTagsToNewFormat() {
        guard let tagsRaw = tagsRaw, !tagsRaw.isEmpty else { return }
        
        // Если теги уже в новом формате (начинаются с ", "), пропускаем
        if tagsRaw.hasPrefix(", ") && tagsRaw.hasSuffix(",") {
            return
        }
        
        // Конвертируем в новый формат
        let currentTags = tags
        setTags(currentTags)
    }
    
    /// Обновляет updatedAt до текущей даты
    func touchUpdatedAt() {
        updatedAt = Date()
    }
}

// MARK: - Array Extension для удаления дубликатов
private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        return Array(Set(self))
    }
}
