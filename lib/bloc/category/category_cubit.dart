import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final ApiProvider apiProvider;

  CategoryCubit(this.apiProvider) : super(CategoryInitial());

  /// Load categories from API using token.
  Future<void> loadCategories(String token) async {
    try {
      emit(CategoryLoading());
      final categories = await apiProvider.fetchCategories(token); // renamed
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError("Error loading categories"));
    }
  }

  /// Create a new category. Normalize color before sending.
  Future<void> createCategory(String name, String colorHex, String token) async {
    try {
      emit(CategoryLoading());

      String normalized = colorHex.trim().replaceAll('#', '').toUpperCase();
      if (!(normalized.length == 6 || normalized.length == 8)) {
        normalized = '808080';
      }

      await apiProvider.createCategory(name, normalized, token);

      await loadCategories(token);
    } catch (e) {
      emit(CategoryError("Could not create category"));
    }
  }

  /// Delete a category and reload list.
  Future<void> deleteCategory(int id, String token) async {
    try {
      emit(CategoryLoading());
      await apiProvider.deleteCategory(id, token);
      await loadCategories(token);
    } catch (e) {
      emit(CategoryError("Could not delete category"));
    }
  }
  // Agrega esto a tu CategoryCubit
  Future<void> updateCategory(int id, String name, String colorHex, String token) async {
    try {
      emit(CategoryLoading());
      
      // Normalizamos el color igual que en create
      String normalized = colorHex.trim().replaceAll('#', '').toUpperCase();
      if (!(normalized.length == 6 || normalized.length == 8)) {
        normalized = '808080';
      }

      await apiProvider.updateCategory(id, name, normalized, token);
      await loadCategories(token); // Recargamos la lista
    } catch (e) {
      emit(CategoryError("Could not update category"));
    }
  }

  /// Reset cubit state to initial (useful on logout).
  void reset() {
    emit(CategoryInitial());
  }
}