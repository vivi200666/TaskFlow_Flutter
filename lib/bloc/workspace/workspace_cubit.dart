import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'workspace_state.dart';

class WorkspaceCubit extends Cubit<WorkspaceState> {
  final ApiProvider apiProvider;

  WorkspaceCubit(this.apiProvider) : super(WorkspaceInitial());

  /// Load the list of workspaces of the user from API
  Future<void> loadWorkspaces(String token) async {
    try {
      emit(WorkspaceLoading());
      final list = await apiProvider.fetchWorkspaces(token); // renamed
      final workspaces = (list is List) ? List<dynamic>.from(list) : <dynamic>[];
      emit(WorkspaceLoaded(workspaces: workspaces));
    } catch (e) {
      emit(WorkspaceError("Could not load workspaces: ${e.toString()}"));
    }
  }

  /// Create a new workspace in the backend
  Future<bool> createWorkspace(String name, String description, String token) async {
    try {
      emit(WorkspaceLoading());
      final success = await apiProvider.createWorkspace(name, description, token);
      if (success == true) {
        await loadWorkspaces(token);
        return true;
      } else {
        emit(WorkspaceError("Could not create workspace"));
        return false;
      }
    } catch (e) {
      emit(WorkspaceError("Error creating workspace: ${e.toString()}"));
      return false;
    }
  }

  /// Join a workspace using access code
  Future<bool> joinWorkspace(String code, String token) async {
    try {
      emit(WorkspaceLoading());
      final success = await apiProvider.joinWorkspace(code, token);
      if (success == true) {
        return true;
      } else {
        emit(WorkspaceError("Invalid code or could not join workspace"));
        return false;
      }
    } catch (e) {
      emit(WorkspaceError("Error joining workspace: ${e.toString()}"));
      return false;
    }
  }

  /// Delete a workspace
  Future<bool> deleteWorkspace(int id, String token) async {
    try {
      emit(WorkspaceLoading());
      final success = await apiProvider.deleteWorkspace(id, token);
      if (success == true) {
        await loadWorkspaces(token);
        return true;
      } else {
        emit(WorkspaceError("Could not delete workspace"));
        return false;
      }
    } catch (e) {
      emit(WorkspaceError("Error deleting workspace: ${e.toString()}"));
      return false;
    }
  }
  /// Fetch workspace members without changing the global state
  Future<List<Map<String, dynamic>>> getWorkspaceMembers(int workspaceId, String token) async {
    try {
      return await apiProvider.fetchWorkspaceMembers(workspaceId, token);
    } catch (e) {
      return [];
    }
  }

  /// Reset cubit state to initial
  void reset() {
    emit(WorkspaceInitial());
  }
}