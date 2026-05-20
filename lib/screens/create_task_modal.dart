import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/task/task_cubit.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/category/category_cubit.dart';
import '../bloc/category/category_state.dart';
import '../../models/task_model.dart';
import '../models/category_model.dart';

class CreateTaskModal extends StatefulWidget {
  final Task? task;
  final int? initialCategoryId;
  const CreateTaskModal({super.key, this.task, this.initialCategoryId});

  @override
  State<CreateTaskModal> createState() => _CreateTaskModalState();
}

class _CreateTaskModalState extends State<CreateTaskModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedPriority = 'M';
  DateTime? _selectedDate;
  int? _selectedCategory;
  List<Category> _categories = [];
  bool _loadingCategories = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedPriority = widget.task!.priority;
      _selectedCategory = widget.task!.categoryId;
      if (widget.task!.dueDate != null) {
        _selectedDate = DateTime.tryParse(widget.task!.dueDate!);
      }
    } else if (widget.initialCategoryId != null) {
      _selectedCategory = widget.initialCategoryId;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final categoryState = context.read<CategoryCubit>().state;
    if (categoryState is CategoryLoaded) {
      setState(() {
        _categories = categoryState.categories;
        _loadingCategories = false;
      });
    } else {
      setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    if (_isSaving) return;
    setState(() => _isSaving = true);

    String? formattedDate;
    if (_selectedDate != null) {
      formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    final payload = <String, dynamic>{
      'titulo': _titleController.text.trim(),
      'descripcion': _descriptionController.text.trim(),
      'prioridad': _selectedPriority,
      'fecha_vencimiento': formattedDate,
    };
    if (_selectedCategory != null) {
      payload['categoria'] = _selectedCategory;
    }

    if (widget.task == null) {
      await context.read<TaskCubit>().createTask(payload, authState.token);
    } else {
      await context.read<TaskCubit>().updateTask(widget.task!.id, payload, authState.token);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('🔴 High')),
                  DropdownMenuItem(value: 'M', child: Text('🟡 Medium')),
                  DropdownMenuItem(value: 'B', child: Text('🟢 Low')),
                ],
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedDate == null ? 'No date' : DateFormat('MM/dd/yyyy').format(_selectedDate!)),
                      if (_selectedDate != null)
                        IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _selectedDate = null)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _loadingCategories
                  ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  : DropdownButtonFormField<int>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label)),
                      hint: const Text('No category'),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Row(
                            children: [
                              Container(width: 16, height: 16, decoration: BoxDecoration(color: cat.getColor(), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveTask,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}