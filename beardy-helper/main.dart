import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(BeardyHelper());
}

class BeardyHelper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beardy Helper',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey,
      ),
      home: MainMenu(),
    );
  }
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  List<String> dragonNames = [];
  TextEditingController dragonController = TextEditingController();
  String statusMessage = "";

  @override
  void initState() {
    super.initState();
    _loadDragonNames();
  }

  Future<void> _loadDragonNames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      dragonNames = prefs.getStringList('dragons') ?? [];
    });
  }

  Future<void> _addDragon() async {
    String name = dragonController.text.trim();
    if (name.isNotEmpty && !dragonNames.contains(name)) {
      dragonNames.add(name);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dragons', dragonNames);
      dragonController.clear();
      setState(() {
        statusMessage = "Dragon '$name' added!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset('assets/leaf menu.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/beardybuddylogo.png', height: 100),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dragonController,
                            decoration: InputDecoration(
                              hintText: "Dragon name",
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _addDragon,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(0, 50),
                            backgroundColor: Color.fromRGBO(0, 43, 0, 1),
                          ),
                          child: Image.asset('assets/add.png', height: 50),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _showSelectPopup(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: Image.asset('assets/select a dragon (2).png', height: 50),
                    ),
                    SizedBox(height: 10),
                    Text(statusMessage, style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSelectPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select a Dragon"),
        content: SingleChildScrollView(
          child: Column(
            children: dragonNames.map((name) => ListTile(
              title: Text(name),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CategoryMenu(dragonName: name)),
                );
              },
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class CategoryMenu extends StatefulWidget {
  final String dragonName;

  CategoryMenu({required this.dragonName});

  @override
  _CategoryMenuState createState() => _CategoryMenuState();
}

class _CategoryMenuState extends State<CategoryMenu> {
  static const Map<String, List<String>> CATEGORIES = {
    "Feeding": ["Fed bugs", "Fed vegetables", "Last fed calcium with D3", "Gave water", "Fed snack", "Fed sugar", "Special Food"],
    "Health": ["Gave bath", "Last poop date", "Vet visit", "Last shed date", "Medical Info", "Weight"],
    "Tank": ["Deep cleaned tank", "Changed UVB light", "Changed basking bulb", "Changed substrate"],
    "Environment": [],
    "Reminders": ["Changed UVB light", "Changed basking bulb", "Deep cleaned tank", "Last fed calcium with D3",
                  "Fed bugs", "Vet visit", "Changed substrate", "Gave bath", "Fed snack", "Fed sugar", "Special Food"],
    "Controls": []
  };
  static const Color GREEN_COLOR = Color.fromRGBO(0, 43, 0, 1);
  Map<String, List<String>> taskDates = {};
  Map<String, String> reminderIntervals = {};
  String statusMessage = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(widget.dragonName);
    if (data != null) {
      Map<String, dynamic> loaded = jsonDecode(data);
      taskDates = loaded.map((key, value) => MapEntry(key, List<String>.from(value)));
      reminderIntervals = Map<String, String>.from(
        Map.fromEntries(
          (taskDates["ReminderIntervals"] ?? []).map((entry) {
            var parts = entry.split(':');
            return MapEntry(parts[0], parts.length > 1 ? parts[1] : "0");
          })
        ) ?? {for (var t in CATEGORIES["Reminders"]!) t: "0"}
      );
    } else {
      taskDates = {for (var task in CATEGORIES.values.expand((tasks) => tasks)) task: []};
      taskDates["Tank Temperatures"] = ["Cold End F:Not set", "Cold End C:Not set", "Hot End F:Not set", "Hot End C:Not set"];
      taskDates["Weight"] = ["Not recorded"];
      taskDates["Humidity"] = ["Not recorded"];
      reminderIntervals = {for (var t in CATEGORIES["Reminders"]!) t: "0"};
      taskDates["ReminderIntervals"] = reminderIntervals.entries.map((e) => "${e.key}:${e.value}").toList();
    }
    setState(() {});
  }

  Future<void> _saveData() async {
    List<String> reminderList = reminderIntervals.entries.map((e) => "${e.key}:${e.value}").toList();
    taskDates["ReminderIntervals"] = reminderList;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.dragonName, jsonEncode(taskDates));
    List<String> dragons = prefs.getStringList('dragons') ?? [];
    if (!dragons.contains(widget.dragonName)) dragons.add(widget.dragonName);
    await prefs.setStringList('dragons', dragons);
  }

  void _updateTaskDate(String task, {String? info}) {
    String now = DateFormat('MMMM d, yyyy \'at\' hh:mm a').format(DateTime.now());
    if (!taskDates.containsKey(task)) taskDates[task] = [];
    taskDates[task]!.add(info ?? now);
    if (CATEGORIES["Reminders"]!.contains(task) && int.parse(reminderIntervals[task]!) > 0) {
      _updateReminder(task, info ?? now);
    }
    statusMessage = "$task at ${info ?? now}";
    _saveData();
    setState(() {});
  }

  void _updateReminder(String task, String lastLog) {
    int reminderDays = int.parse(reminderIntervals[task]!);
    if (reminderDays > 0) {
      DateTime lastDate = DateFormat('MMMM d, yyyy \'at\' hh:mm a').parse(lastLog);
      DateTime nextDue = lastDate.add(Duration(days: reminderDays));
    }
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dragonName)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(10),
        children: CATEGORIES.keys.map((category) => GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CategoryScreen(
              dragonName: widget.dragonName,
              category: category,
              taskDates: taskDates,
              reminderIntervals: reminderIntervals,
              updateTaskDate: _updateTaskDate,
              saveData: _saveData,
            )),
          ),
          child: Card(
            color: GREEN_COLOR,
            child: Center(
              child: Image.asset('assets/${category.toLowerCase()}.png', height: 60),
            ),
          ),
        )).toList()..add(GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Card(
            color: GREEN_COLOR,
            child: Center(
              child: Image.asset('assets/main menumen.png', height: 60),
            ),
          ),
        )),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(10),
        child: Text(statusMessage),
      ),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  final String dragonName;
  final String category;
  final Map<String, List<String>> taskDates;
  final Map<String, String> reminderIntervals;
  final Function(String, {String? info}) updateTaskDate;
  final Future<void> Function() saveData;

  CategoryScreen({
    required this.dragonName,
    required this.category,
    required this.taskDates,
    required this.reminderIntervals,
    required this.updateTaskDate,
    required this.saveData,
  });

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const Color GREEN_COLOR = Color.fromRGBO(0, 43, 0, 1);
  TextEditingController hotInput = TextEditingController();
  TextEditingController coldInput = TextEditingController();
  TextEditingController humInput = TextEditingController();
  String hotUnit = "F";
  String coldUnit = "F";
  Map<String, TextEditingController> reminderInputs = {};

  @override
  void initState() {
    super.initState();
    hotInput.text = widget.taskDates["Tank Temperatures"]?.firstWhere((e) => e.startsWith("Hot End F"), orElse: () => "Hot End F:Not set")?.split(":")[1] ?? "Not set";
    coldInput.text = widget.taskDates["Tank Temperatures"]?.firstWhere((e) => e.startsWith("Cold End F"), orElse: () => "Cold End F:Not set")?.split(":")[1] ?? "Not set";
    humInput.text = widget.taskDates["Humidity"]?.first.replaceAll("%", "") ?? "Not recorded";
    widget.reminderIntervals.forEach((task, value) {
      reminderInputs[task] = TextEditingController(text: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.dragonName} - ${widget.category}")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.category == "Environment") _buildEnvironmentMonitor(),
            if (widget.category == "Reminders") _buildReminders(),
            if (["Feeding", "Health", "Tank"].contains(widget.category)) _buildTaskList(),
            if (widget.category == "Controls") _buildControls(),
            SizedBox(height: 10),
            if (["Feeding", "Health", "Tank", "Reminders"].contains(widget.category))
              _buildBottomSection(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(10),
        child: Text(widget.taskDates["status"]?.first ?? ""),
      ),
    );
  }

  Widget _buildTaskList() {
    return Column(
      children: BeardyHelper.CATEGORIES[widget.category]!.map((task) {
        return task == "Medical Info" ? _buildMedicalInfoButton() :
          task == "Weight" ? _buildWeightButton() :
          ElevatedButton(
            onPressed: () => task == "Vet visit" ? _showVetVisitPopup() :
              ["Special Food", "Fed sugar", "Fed snack"].contains(task) ? _showFoodInputPopup(task) :
              widget.updateTaskDate(task),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 40),
              backgroundColor: GREEN_COLOR,
            ),
            child: Text(task),
          );
      }).toList(),
    );
  }

  Widget _buildMedicalInfoButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _addMedicalInfo,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 40),
            backgroundColor: GREEN_COLOR,
          ),
          child: Text("Medical Info"),
        ),
        ElevatedButton(
          onPressed: _showInfoSheet,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 40),
            backgroundColor: GREEN_COLOR,
          ),
          child: Text("Info Sheet"),
        ),
      ],
    );
  }

  Widget _buildWeightButton() {
    return ElevatedButton(
      onPressed: _showWeightInputPopup,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 40),
        backgroundColor: GREEN_COLOR,
      ),
      child: Text("Weight"),
    );
  }

  Widget _buildEnvironmentMonitor() {
    return Card(
      color: GREEN_COLOR.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Hot:", style: TextStyle(color: Colors.white)),
                SizedBox(width: 10),
                Expanded(child: TextField(controller: hotInput, style: TextStyle(color: Colors.black))),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: hotUnit,
                  items: ["F", "C"].map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                  onChanged: (value) => setState(() => hotUnit = value!),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Cold:", style: TextStyle(color: Colors.white)),
                SizedBox(width: 10),
                Expanded(child: TextField(controller: coldInput, style: TextStyle(color: Colors.black))),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: coldUnit,
                  items: ["F", "C"].map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                  onChanged: (value) => setState(() => coldUnit = value!),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Hum %:", style: TextStyle(color: Colors.white)),
                SizedBox(width: 10),
                Expanded(child: TextField(controller: humInput, style: TextStyle(color: Colors.black))),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveEnvironmentData,
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminders() {
    return Card(
      color: GREEN_COLOR.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: BeardyHelper.CATEGORIES["Reminders"]!.map((task) => Row(
            children: [
              SizedBox(width: 150, child: Text(task, style: TextStyle(color: Colors.white))),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: reminderInputs[task],
                  decoration: InputDecoration(fillColor: Colors.white, filled: true),
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) => _updateReminderDays(task, value),
                ),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: GREEN_COLOR),
          child: Image.asset('assets/backback.png', height: 60),
        ),
        ElevatedButton(
          onPressed: _resetData,
          style: ElevatedButton.styleFrom(backgroundColor: GREEN_COLOR),
          child: Text("Reset"),
        ),
        ElevatedButton(
          onPressed: _removeDragon,
          style: ElevatedButton.styleFrom(backgroundColor: GREEN_COLOR),
          child: Text("Remove"),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Card(
      color: Colors.black,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Text(widget.category == "Reminders" ? "Next Due Dates" : "Recent Task Times",
              style: TextStyle(color: Colors.white, fontSize: 16)),
            SingleChildScrollView(
              child: Column(
                children: widget.category == "Reminders" ?
                  BeardyHelper.CATEGORIES["Reminders"]!.map((task) {
                    int days = int.parse(reminderInputs[task]!.text.isEmpty ? "0" : reminderInputs[task]!.text);
                    String lastLog = widget.taskDates[task]?.last ?? "";
                    String dueText = days > 0 && lastLog.isNotEmpty ?
                      DateFormat('MM/dd/yyyy').format(DateFormat('MMMM d, yyyy \'at\' hh:mm a').parse(lastLog).add(Duration(days: days))) :
                      "N/A";
                    return Text("$task: Due $dueText", style: TextStyle(color: Colors.white));
                  }).toList() :
                  BeardyHelper.CATEGORIES[widget.category]!.where((task) => task != "Medical Info" && task != "Weight").map((task) {
                    return Text("$task: ${widget.taskDates[task]?.last ?? 'Never'}", style: TextStyle(color: Colors.white));
                  }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVetVisitPopup() {
    DateTime now = DateTime.now();
    String month = DateFormat('MMMM').format(now);
    String day = now.day.toString();
    String year = now.year.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Vet Visit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: month,
                  items: List.generate(12, (i) => DateTime(2025, i + 1, 1).monthName())
                      .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (value) => setState(() => month = value!),
                ),
                DropdownButton<String>(
                  value: day,
                  items: List.generate(31, (i) => (i + 1).toString())
                      .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (value) => setState(() => day = value!),
                ),
                DropdownButton<String>(
                  value: year,
                  items: List.generate(11, (i) => (2020 + i).toString())
                      .map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (value) => setState(() => year = value!),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                widget.updateTaskDate("Vet visit");
                Navigator.pop(context);
              },
              child: Text("Now"),
            ),
            ElevatedButton(
              onPressed: () {
                widget.updateTaskDate("Vet visit", "$month $day, $year at ${DateFormat('hh:mm a').format(DateTime.now())}");
                Navigator.pop(context);
              },
              child: Text("Set Date"),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodInputPopup(String task) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Log $task"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter $task (e.g., strawberries)"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.updateTaskDate(task, controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showWeightInputPopup() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Log Weight"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter weight (e.g., 350g)"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.taskDates["Weight"] = [controller.text];
              widget.saveData();
              setState(() {});
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _addMedicalInfo() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Medical Info"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "e.g., checked for parasites"),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.updateTaskDate("Medical Info", controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet() {
    String infoText = "Info Sheet for ${widget.dragonName}\n\n" +
        "Dragon Name: ${widget.dragonName}\n" +
        "Weight: ${widget.taskDates['Weight']?.first ?? 'Not recorded'}\n" +
        "Humidity: ${widget.taskDates['Humidity']?.first ?? 'Not recorded'}\n" +
        "Tank Temperatures:\n" +
        "  Hot End: ${widget.taskDates['Tank Temperatures']?.firstWhere((e) => e.startsWith('Hot End F'), orElse: () => 'Hot End F:Not set')?.split(':')[1] ?? 'Not set'} F / " +
        "${widget.taskDates['Tank Temperatures']?.firstWhere((e) => e.startsWith('Hot End C'), orElse: () => 'Hot End C:Not set')?.split(':')[1] ?? 'Not set'} C\n" +
        "  Cold End: ${widget.taskDates['Tank Temperatures']?.firstWhere((e) => e.startsWith('Cold End F'), orElse: () => 'Cold End F:Not set')?.split(':')[1] ?? 'Not set'} F / " +
        "${widget.taskDates['Tank Temperatures']?.firstWhere((e) => e.startsWith('Cold End C'), orElse: () => 'Cold End C:Not set')?.split(':')[1] ?? 'Not set'} C\n" +
        "\nMedical Info:\n" +
        (widget.taskDates["Medical Info"]?.map((log) => "  $log").join("\n") ?? "  No medical info recorded") +
        "\n";
    BeardyHelper.CATEGORIES.values.expand((tasks) => tasks).toSet().forEach((task) {
      if (task != "Medical Info") {
        infoText += "\n$task:\n" +
            (widget.taskDates[task]?.take(30).map((log) => "  $log").join("\n") ?? "  No logs recorded");
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Info Sheet"),
        content: SingleChildScrollView(child: Text(infoText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Image.asset('assets/backback.png', height: 60),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: infoText));
              Navigator.pop(context);
            },
            child: Text("Copy"),
          ),
        ],
      ),
    );
  }

  void _saveEnvironmentData() {
    widget.taskDates["Tank Temperatures"] = [
      "Hot End $hotUnit:${hotInput.text.isNotEmpty ? hotInput.text : 'Not set'}",
      "Cold End $coldUnit:${coldInput.text.isNotEmpty ? coldInput.text : 'Not set'}",
      "Hot End C:${widget.taskDates['Tank Temperatures']?.firstWhere((e) => e.startsWith('Hot End C'), orElse: () => 'Hot End C:Not set')?.split(':')[1] ?? 'Not set'}",
      "Cold End F:${widget.taskDates['Tank Temperatures']?.firstWhere((e) => e.startsWith('Cold End F'), orElse: () => 'Cold End F:Not set')?.split(':')[1] ?? 'Not set'}"
    ];
    widget.taskDates["Humidity"] = [humInput.text.isNotEmpty ? "${humInput.text}%" : "Not recorded"];
    widget.taskDates["status"] = ["Env updated ${DateFormat('MM/dd/yyyy').format(DateTime.now())}"];
    widget.saveData();
    setState(() {});
  }

  void _resetData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset?"),
        content: Text("Reset all data?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("No")),
          TextButton(
            onPressed: () {
              widget.taskDates = {for (var task in BeardyHelper.CATEGORIES.values.expand((tasks) => tasks)) task: []};
              widget.taskDates["Tank Temperatures"] = ["Hot End F:Not set", "Hot End C:Not set", "Cold End F:Not set", "Cold End C:Not set"];
              widget.taskDates["Weight"] = ["Not recorded"];
              widget.taskDates["Humidity"] = ["Not recorded"];
              widget.reminderIntervals = {for (var t in BeardyHelper.CATEGORIES["Reminders"]!) t: "0"};
              widget.taskDates["ReminderIntervals"] = widget.reminderIntervals.entries.map((e) => "${e.key}:${e.value}").toList();
              widget.saveData();
              setState(() {});
              Navigator.pop(context);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _removeDragon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove?"),
        content: Text("Remove '${widget.dragonName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("No")),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              List<String> dragons = prefs.getStringList('dragons') ?? [];
              dragons.remove(widget.dragonName);
              await prefs.setStringList('dragons', dragons);
              await prefs.remove(widget.dragonName);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _updateReminderDays(String task, String value) {
    if (int.tryParse(value) != null) {
      widget.reminderIntervals[task] = value;
      String? lastLog = widget.taskDates[task]?.last;
      if (lastLog != null && int.parse(value) > 0) _updateReminder(task, lastLog);
      widget.saveData();
    }
  }
}

extension DateTimeExtension on DateTime {
  String monthName() => DateFormat('MMMM').format(this);
}