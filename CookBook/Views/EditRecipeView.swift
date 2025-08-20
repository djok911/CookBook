//
//  EditRecipeView.swift
//  CookBook
//
//  Created by Ivan Huttunen on 20.08.2025.
//

import SwiftUI
import PhotosUI

struct EditRecipeView: View {
    let recipe: Recipe
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var ingredients: String
    @State private var steps: String
    @State private var tagsInput: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingImage = false
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _title = State(initialValue: recipe.title ?? "")
        _ingredients = State(initialValue: recipe.ingredients ?? "")
        _steps = State(initialValue: recipe.instructions ?? "")
        _tagsInput = State(initialValue: recipe.tagsRaw ?? "")
        _imageData = State(initialValue: recipe.imageData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    TextField("Название рецепта *", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Ингредиенты", text: $ingredients, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Шаги приготовления", text: $steps, axis: .vertical)
                        .lineLimit(5...12)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Теги") {
                    TextField("Теги (через запятую)", text: $tagsInput)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Фото блюда") {
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                showingImage = true
                            }
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(imageData == nil ? "Выбрать фото" : "Изменить фото")
                        }
                    }
                    .onChange(of: selectedPhoto) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }
                    
                    if imageData != nil {
                        Button(role: .destructive, action: {
                            imageData = nil
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Удалить фото")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Редактировать рецепт")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Отмена") {
                    dismiss()
                },
                trailing: Button("Сохранить") {
                    updateRecipe()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .fullScreenCover(isPresented: $showingImage) {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    ImageViewer(image: uiImage, isPresented: $showingImage)
                }
            }
        }
    }
    
    private func updateRecipe() {
        // Нормализуем теги
        let normalizedTags = ImageService.normalizeTags(from: tagsInput)
        
        // Обрабатываем изображение
        var processedImageData: Data?
        if let imageData = imageData {
            processedImageData = ImageService.compressAndResizeImage(imageData)
        }
        
        // Обновляем рецепт
        recipe.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.ingredients = ingredients.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.instructions = steps.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.imageData = processedImageData
        recipe.setTags(normalizedTags)
        recipe.touchUpdatedAt()
        
        // Сохраняем в Core Data
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Ошибка обновления рецепта: \(error)")
        }
    }
}

#Preview {
    EditRecipeView(recipe: Recipe())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
