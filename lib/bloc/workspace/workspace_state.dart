import 'package:equatable/equatable.dart';

abstract class WorkspaceState extends Equatable {
  const WorkspaceState();
  @override
  List<Object?> get props => [];
}

class WorkspaceInitial extends WorkspaceState {}

class WorkspaceLoading extends WorkspaceState {}

class WorkspaceLoaded extends WorkspaceState {
  final List<dynamic> workspaces;

  const WorkspaceLoaded({required this.workspaces});

  @override
  List<Object?> get props => [workspaces];
}

class WorkspaceError extends WorkspaceState {
  final String message;
  const WorkspaceError(this.message);

  @override
  List<Object?> get props => [message];
}