//
//  AddRecipeView.swift
//  CookBook
//
//  Created by Ivan Huttunen on 20.08.2025.
//

import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var ingredients = ""
    @State private var steps = ""
    @State private var tagsInput = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingImage = false
    
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
                }
            }
            .navigationTitle("Новый рецепт")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Отмена") {
                    dismiss()
                },
                trailing: Button("Сохранить") {
                    saveRecipe()
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
    
    private func saveRecipe() {
        // Нормализуем теги
        let normalizedTags = ImageService.normalizeTags(from: tagsInput)
        
        // Обрабатываем изображение
        var processedImageData: Data?
        if let imageData = imageData {
            processedImageData = ImageService.compressAndResizeImage(imageData)
        }
        
        // Создаем новый рецепт
        let recipe = Recipe(context: viewContext)
        recipe.id = UUID()
        recipe.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.ingredients = ingredients.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.instructions = steps.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.imageData = processedImageData
        recipe.setTags(normalizedTags)
        recipe.createdAt = Date()
        recipe.updatedAt = Date()
        
        // Сохраняем в Core Data
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Ошибка сохранения рецепта: \(error)")
        }
    }
}

// MARK: - ImageViewer для просмотра изображения в полноэкранном режиме
struct ImageViewer: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.black)
            }
            .navigationTitle("Просмотр фото")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Закрыть") {
                    isPresented = false
                }
            )
        }
    }
}

#Preview {
    AddRecipeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
