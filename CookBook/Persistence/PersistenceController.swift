//
//  PersistenceController.swift
//  CookBook
//
//  Created by Ivan Huttunen on 20.08.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Создаем тестовые рецепты для превью
        let sampleRecipes = [
            ("Борщ", "свекла, капуста, картошка, мясо", "Варить мясо, добавить овощи", ["суп", "традиционный", "украинский"]),
            ("Паста Карбонара", "паста, яйца, бекон, сыр", "Сварить пасту, обжарить бекон", ["итальянский", "паста", "быстрый"]),
            ("Салат Цезарь", "салат, курица, сухарики, соус", "Нарезать ингредиенты, заправить", ["салат", "легкий", "здоровый"]),
            ("Пицца Маргарита", "тесто, томаты, моцарелла, базилик", "Раскатать тесто, добавить начинку", ["пицца", "итальянский", "вегетарианский"]),
            ("Шоколадный торт", "мука, какао, сахар, яйца", "Смешать ингредиенты, запечь", ["десерт", "сладкий", "шоколад"])
        ]
        
        for (title, ingredients, instructions, tags) in sampleRecipes {
            let recipe = Recipe(context: viewContext)
            recipe.title = title
            recipe.ingredients = ingredients
            recipe.instructions = instructions
            recipe.setTags(tags) // Используем новый метод setTags
            recipe.createdAt = Date()
            recipe.updatedAt = Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CookBook")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Настройка lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Мигрируем существующие теги в новый формат
        migrateExistingTags()
    }
    
    /// Мигрирует существующие теги в новый формат ",tag,"
    private func migrateExistingTags() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        
        do {
            let recipes = try context.fetch(fetchRequest)
            var hasChanges = false
            
            for recipe in recipes {
                recipe.migrateTagsToNewFormat()
                hasChanges = true
            }
            
            if hasChanges {
                try context.save()
                print("Successfully migrated \(recipes.count) recipes to new tag format")
            }
        } catch {
            print("Error migrating tags: \(error)")
        }
    }
}
