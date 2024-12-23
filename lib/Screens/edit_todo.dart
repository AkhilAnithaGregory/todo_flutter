import 'package:flutter/material.dart';
import 'todo_dashboard.dart';

void main() => runApp(const EditTodoApp());

class EditTodoApp extends StatelessWidget {
  const EditTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: EditTodo(),
    );
  }
}

class EditTodo extends StatefulWidget {
  const EditTodo({super.key});

  @override
  State<EditTodo> createState() => _EditTodoState();
}

class _EditTodoState extends State<EditTodo> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();

  void _EditTodo() {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text;
      final String detail = _detailController.text;

      print('Title: $title');
      print('Detail: $detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADD TODO',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9395D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'Detail',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some detail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _EditTodo,
                  child: const Text('Add Todo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9395D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _EditTodo,
                      child: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9395D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Dashboard()),
                        );
                      },
                      child: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9395D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                      ),
                    ),
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
