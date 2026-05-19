import 'package:equatable/equatable.dart';

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override
  List<Object?> get props => [message];
}

class TaskLoadedPersonal extends TaskState {
  final List<Map<String, dynamic>> tasks;
  const TaskLoadedPersonal({required this.tasks});
  @override
  List<Object?> get props => [tasks];
}

class TaskLoadedWorkspace extends TaskState {
  final List<Map<String, dynamic>> tasks;
  const TaskLoadedWorkspace({required this.tasks});
  @override
  List<Object?> get props => [tasks];
}

class TaskCreated extends TaskState {
  final Map<String, dynamic> task;
  const TaskCreated({required this.task});
  @override
  List<Object?> get props => [task];
}

class TaskUpdated extends TaskState {
  final Map<String, dynamic> task;
  const TaskUpdated({required this.task});
  @override
  List<Object?> get props => [task];
}

class TaskDeleted extends TaskState {
  final int id;
  const TaskDeleted({required this.id});
  @override
  List<Object?> get props => [id];
}