import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app_pro1/view/home_page/dialog_box/dialog_box.dart';
import 'package:todo_app_pro1/view/home_page/todo_tile/todo_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List _toDoList = [];

  @override
  void initState() {
    super.initState();
    final myBox = Hive.box('myBox');
    _toDoList = myBox.get("TODOLIST", defaultValue: []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial(context);
    });
  }

  Future<void> _showTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool? noteAdded = prefs.getBool('noteAdded');

    if (noteAdded != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tap + to add a new note'),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDeleteTipIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    bool? deleteTipShown = prefs.getBool('deleteTipShown');

    if (deleteTipShown != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Swipe left to delete the note'),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await prefs.setBool('deleteTipShown', true);
    }
  }

  void checkBoxChanged(bool? value, int index) {
    setState(() {
      _toDoList[index][1] = value;
    });
    _updateHive();
  }

  void deleteTask(int index) {
    setState(() {
      _toDoList.removeAt(index);
    });
    _updateHive();
  }

  Future<void> saveNewTask(BuildContext dialogContext) async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _toDoList.add([_controller.text, false]);
      _controller.clear();
    });
    _updateHive();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noteAdded', true);
    Navigator.of(dialogContext).pop();

    _showDeleteTipIfNeeded();
  }

  void createNewTask() {
    setState(() {});
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onSave: () => saveNewTask(context),
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _updateHive() {
    final myBox = Hive.box("myBox");
    myBox.put("TODOLIST", _toDoList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[200],
      appBar: AppBar(
        title: Text('TODO', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: createNewTask,
        child: Icon(Icons.add),
      ),
      body: SlidableAutoCloseBehavior(
        // ✅ Only this is needed!
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: ListView.builder(
            itemCount: _toDoList.length,
            itemBuilder: (context, index) {
              return Slidable(
                key: ValueKey(index),
                endActionPane: ActionPane(
                  motion: DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) => deleteTask(index),
                      backgroundColor: Colors.yellow.shade400,
                      foregroundColor: Colors.black,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ToDoTile(
                  taskName: _toDoList[index][0],
                  taskCompleted: _toDoList[index][1],
                  onChanged: (value) => checkBoxChanged(value, index),
                  onDelete: () => deleteTask(index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
