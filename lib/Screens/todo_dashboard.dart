import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'add_todo.dart';
import 'edit_todo.dart'; // Import EditTodoApp
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  final Logger logger = Logger();
  String _loginToken = '';
  List<dynamic> _todoItems = [];

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'All Items',
      style: optionStyle,
    ),
    Text(
      'Completed Items',
      style: optionStyle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginToken = prefs.getString('loginToken') ?? '';
    });

    if (_loginToken.isNotEmpty) {
      _fetchTodos();
    } else {
      logger.e('No token found');
    }
  }

  Future<void> _fetchTodos([String? date]) async {
    final String selectedDate =
        date ?? DateTime.now().toIso8601String().split('T').first;
    final String url =
        'https://todo-mww8.onrender.com/api/todo?date=$selectedDate';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _loginToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> todos = jsonDecode(response.body);
        setState(() {
          _todoItems = todos;
        });
      } else {
        logger.e('Failed to load todos: ${response.body}');
      }
    } catch (error) {
      logger.e('Error fetching todos: $error');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate = pickedDate.toIso8601String().split('T').first;
      _fetchTodos(formattedDate); // Fetch todos for the selected date
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TODO APP',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9395D2),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today,
              color: Colors.white,
            ),
            onPressed: () {
              _selectDate(context);
            },
          ),
        ],
      ),
      body: Center(
        child: _todoItems.isEmpty
            ? const CircularProgressIndicator()
            : ListView.builder(
                itemCount: _todoItems.length,
                itemBuilder: (context, index) {
                  final todoItem = _todoItems[index];
                  final task = todoItem['task'] ?? 'Untitled';
                  final description =
                      todoItem['description'] ?? 'No description';
                  final isComplete = todoItem['isComplete'] ?? false;
                  final date = DateTime.parse(todoItem['date']);
                  final formattedDate =
                      "${date.year}-${date.month}-${date.day}";
                  final todoId = todoItem['_id'];

                  return ListTile(
                    title: Text(task),
                    subtitle: Text('$description\nDate: $formattedDate'),
                    leading: Icon(
                      isComplete == true
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isComplete == true ? Colors.green : null,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isComplete
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isComplete ? Colors.green : null,
                          ),
                          onPressed: () {
                            _toggleTodoComplete(
                                todoId, formattedDate, isComplete, index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteTodoItem(todoId);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTodoApp(
                                  taskId: todoItem['_id'] ?? "",
                                  task: todoItem['task'] ?? "untitled",
                                  description: todoItem['description'] ??
                                      "No Description",
                                  datePart: todoItem['date'] ?? "",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTodoApp(),
            ),
          );
        },
        backgroundColor: const Color(0xFF9395D2),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'All',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Complete',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> _toggleTodoComplete(
      String todoId, String date, bool isComplete, int index) async {
    final String url = 'https://todo-mww8.onrender.com/api/todo/$todoId';

    try {
      final response = await http.put(
        Uri.parse('$url?date=$date'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': _loginToken,
        },
        body: jsonEncode(<String, dynamic>{
          'isComplete': !isComplete,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _todoItems[index]['isComplete'] = !isComplete;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo status updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update todo')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _deleteTodoItem(String todoId) async {
    final String url = 'https://todo-mww8.onrender.com/api/todo/$todoId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: <String, String>{
          'Authorization': _loginToken,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _todoItems.removeWhere((item) => item['_id'] == todoId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete todo')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
}
