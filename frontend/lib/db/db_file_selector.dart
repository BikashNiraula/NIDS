import 'package:flutter/material.dart';
import 'package:nidswebapp/db/sqlite.dart';

class DatabaseSelector extends StatefulWidget {
  final Function onDatabaseChanged;

  const DatabaseSelector({Key? key, required this.onDatabaseChanged})
      : super(key: key);

  @override
  _DatabaseSelectorState createState() => _DatabaseSelectorState();
}

class _DatabaseSelectorState extends State<DatabaseSelector> {
  final SQLiteHandler _dbHandler = SQLiteHandler();
  final TextEditingController _newDbController = TextEditingController();
  List<String> _availableDatabases = [];
  String _currentDatabase = 'packets.db';

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  @override
  void dispose() {
    _newDbController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabases() async {
    List<String> databases = await _dbHandler.listDatabases();
    if (mounted) {
      setState(() {
        _availableDatabases = databases;
        _currentDatabase = _dbHandler.currentDatabaseName;
      });
    }
  }

  Future<void> _createNewDatabase() async {
    String newDbName = _newDbController.text.trim();
    if (newDbName.isEmpty) return;

    await _dbHandler.setDatabaseFile(newDbName);
    widget.onDatabaseChanged();
    _newDbController.clear();
    await _loadDatabases();
  }

  Future<void> _selectDatabase(String dbName) async {
    await _dbHandler.setDatabaseFile(dbName);
    widget.onDatabaseChanged();
    await _loadDatabases();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.storage),
          SizedBox(width: 8),
          Text('Current Database: $_currentDatabase'),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newDbController,
                  decoration: InputDecoration(
                    hintText: 'Enter new database name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _createNewDatabase,
                child: Text('Create/Open'),
              ),
            ],
          ),
        ),
        if (_availableDatabases.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _availableDatabases.length,
            itemBuilder: (context, index) {
              final dbName = _availableDatabases[index];
              return ListTile(
                title: Text(dbName),
                selected: dbName == _currentDatabase,
                leading: Icon(Icons.storage_rounded),
                onTap: () => _selectDatabase(dbName),
              );
            },
          ),
      ],
    );
  }
}
