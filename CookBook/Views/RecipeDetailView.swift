//
//  RecipeDetailView.swift
//  CookBook
//
//  Created by Ivan Huttunen on 20.08.2025.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Большое изображение
                if let imageData = recipe.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Название
                    Text(recipe.title ?? "Без названия")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Чипы тегов
                    if !recipe.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    
                    // Блок "Ингредиенты"
                    if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ингредиенты")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(ingredients)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Блок "Шаги"
                    if let instructions = recipe.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Шаги")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(instructions)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Рецепт")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditRecipeView(recipe: recipe)
            }
        }
        .confirmationDialog(
            "Удалить рецепт?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                deleteRecipe()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }
    
    private func deleteRecipe() {
        context.delete(recipe)
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: Recipe())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
