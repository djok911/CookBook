//
//  RecipeListView.swift
//  CookBook
//
//  Created by Ivan Huttunen on 20.08.2025.
//

import SwiftUI
import CoreData

struct RecipeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    @State private var tagFilter = ""
    @State private var showingAddRecipe = false
    
    // Динамический @FetchRequest с NSPredicate
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.updatedAt, ascending: false)],
        animation: .default)
    private var recipes: FetchedResults<Recipe>
    
    // Вычисляемое свойство для создания предиката
    private var fetchPredicate: NSPredicate? {
        var predicates: [NSPredicate] = []
        
        // Предикат для поиска по названию
        if !searchText.isEmpty {
            let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
            predicates.append(titlePredicate)
        }
        
        // Предикат для фильтрации по тегу
        if !tagFilter.isEmpty {
            // Ищем тег в формате ", tag," чтобы избежать частичных совпадений
            let tagPredicate = NSPredicate(format: "tagsRaw CONTAINS[cd] %@", ", \(tagFilter.lowercased()),")
            predicates.append(tagPredicate)
        }
        
        // Комбинируем предикаты через AND
        if !predicates.isEmpty {
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        return nil
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поля поиска и фильтрации
                VStack(spacing: 12) {
                    TextField("Поиск по названию...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Фильтр по тегу...", text: $tagFilter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color(.systemGroupedBackground))
                
                // Список рецептов
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(recipes, id: \.self) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeCardView(recipe: recipe)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Рецепты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRecipe = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .onChange(of: searchText) { _ in
                updateFetchRequest()
            }
            .onChange(of: tagFilter) { _ in
                updateFetchRequest()
            }
        }
    }
    
    private func updateFetchRequest() {
        recipes.nsPredicate = fetchPredicate
    }
    
    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            offsets.map { recipes[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Обработка ошибок сохранения
                print("Error deleting recipe: \(error)")
            }
        }
    }
}

// MARK: - RecipeCardView
struct RecipeCardView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Миниатюра с фиксированным размером
                RecipeImageView(imageData: recipe.imageData)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Информация о рецепте
                VStack(alignment: .leading, spacing: 8) {
                    // Заголовок
                    Text(recipe.title ?? "Без названия")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Описание (ингредиенты)
                    if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                        Text(ingredients)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Теги с переносом
                    if !recipe.tags.isEmpty {
                        TagsView(tags: recipe.tags)
                    }
                }
                
                Spacer()
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - RecipeImageView
struct RecipeImageView: View {
    let imageData: Data?
    
    var body: some View {
        Group {
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
}

// MARK: - TagsView
struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 60, maximum: 120), spacing: 6)
        ], spacing: 6) {
            ForEach(tags.prefix(6), id: \.self) { tag in
                Text(tag.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
            
            if tags.count > 6 {
                Text("+\(tags.count - 6)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray4))
                    )
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - RecipeRowView (оставляем для совместимости)
struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        RecipeCardView(recipe: recipe)
    }
}

#Preview {
    RecipeListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
