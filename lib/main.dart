import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BakeryApp());
}

// --- ډیټا موډلونه ---
class BakeryRecord {
  final String date, sale, expenseAmount, expenseReason, attaQty, attaPrice, gasQty, gasPrice, timestamp;
  BakeryRecord({required this.date, required this.sale, required this.expenseAmount, required this.expenseReason, required this.attaQty, required this.attaPrice, required this.gasQty, required this.gasPrice, required this.timestamp});
  Map<String, dynamic> toJson() => {'date': date, 'sale': sale, 'expenseAmount': expenseAmount, 'expenseReason': expenseReason, 'attaQty': attaQty, 'attaPrice': attaPrice, 'gasQty': gasQty, 'gasPrice': gasPrice, 'timestamp': timestamp};
  factory BakeryRecord.fromJson(Map<String, dynamic> json) => BakeryRecord(date: json['date'] ?? "", sale: json['sale'] ?? "0", expenseAmount: json['expenseAmount'] ?? "0", expenseReason: json['expenseReason'] ?? "", attaQty: json['attaQty'] ?? "0", attaPrice: json['attaPrice'] ?? "0", gasQty: json['gasQty'] ?? "0", gasPrice: json['gasPrice'] ?? "0", timestamp: json['timestamp'] ?? "");
}

class PersonalRecord {
  final String date, title, amount, type;
  PersonalRecord({required this.date, required this.title, required this.amount, required this.type});
  Map<String, dynamic> toJson() => {'date': date, 'title': title, 'amount': amount, 'type': type};
  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(date: json['date'] ?? "", title: json['title'] ?? "", amount: json['amount'] ?? "0", type: json['type'] ?? 'expense');
}

class DebtRecord {
  final String date, name, totalAmount, paidAmount, reason, debtType; 
  DebtRecord({required this.date, required this.name, required this.totalAmount, required this.paidAmount, required this.reason, required this.debtType});
  double get remaining => (double.tryParse(totalAmount) ?? 0) - (double.tryParse(paidAmount) ?? 0);
  Map<String, dynamic> toJson() => {'date': date, 'name': name, 'totalAmount': totalAmount, 'paidAmount': paidAmount, 'reason': reason, 'debtType': debtType};
  factory DebtRecord.fromJson(Map<String, dynamic> json) => DebtRecord(date: json['date'] ?? "", name: json['name'] ?? "", totalAmount: json['totalAmount'] ?? "0", paidAmount: json['paidAmount'] ?? "0", reason: json['reason'] ?? "", debtType: json['debtType'] ?? 'to_me');
}

class HawalaRecord {
  final String date, sender, receiver, amount, code, status; 
  HawalaRecord({required this.date, required this.sender, required this.receiver, required this.amount, required this.code, required this.status});
  Map<String, dynamic> toJson() => {'date': date, 'sender': sender, 'receiver': receiver, 'amount': amount, 'code': code, 'status': status};
  factory HawalaRecord.fromJson(Map<String, dynamic> json) => HawalaRecord(date: json['date'] ?? "", sender: json['sender'] ?? "", receiver: json['receiver'] ?? "", amount: json['amount'] ?? "0", code: json['code'] ?? "", status: json['status'] ?? 'pending');
}

class WorkerSalary {
  final String name; final double salary, received;
  WorkerSalary({required this.name, required this.salary, required this.received});
  double get balance => salary - received;
  Map<String, dynamic> toJson() => {'name': name, 'salary': salary, 'received': received};
  factory WorkerSalary.fromJson(Map<String, dynamic> json) => WorkerSalary(name: json['name'] ?? "", salary: (json['salary'] as num?)?.toDouble() ?? 0.0, received: (json['received'] as num?)?.toDouble() ?? 0.0);
}

class MonthlySummary {
  final String monthYear; final double totalSale, totalKhata, dailyExp, otherExp, workerBal, attaExp, gasExp, netProfit; final List<BakeryRecord> dailyRecords;
  MonthlySummary({required this.monthYear, required this.totalSale, required this.totalKhata, required this.dailyExp, required this.otherExp, required this.workerBal, required this.attaExp, required this.gasExp, required this.netProfit, required this.dailyRecords});
  Map<String, dynamic> toJson() => {'monthYear': monthYear, 'totalSale': totalSale, 'totalKhata': totalKhata, 'dailyExp': dailyExp, 'otherExp': otherExp, 'workerBal': workerBal, 'attaExp': attaExp, 'gasExp': gasExp, 'netProfit': netProfit, 'dailyRecords': dailyRecords.map((r) => r.toJson()).toList()};
  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(monthYear: json['monthYear'] ?? "", totalSale: (json['totalSale'] as num?)?.toDouble() ?? 0.0, totalKhata: (json['totalKhata'] as num?)?.toDouble() ?? 0.0, dailyExp: (json['dailyExp'] as num?)?.toDouble() ?? 0.0, otherExp: (json['otherExp'] as num?)?.toDouble() ?? 0.0, workerBal: (json['workerBal'] as num?)?.toDouble() ?? 0.0, attaExp: (json['attaExp'] as num?)?.toDouble() ?? 0.0, gasExp: (json['gasExp'] as num?)?.toDouble() ?? 0.0, netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0, dailyRecords: (json['dailyRecords'] as List?)?.map((r) => BakeryRecord.fromJson(r)).toList() ?? []);
}

// --- Global Variables ---
List<BakeryRecord> allRecords = [];
List<PersonalRecord> personalRecords = [];
List<DebtRecord> debtRecords = [];
List<HawalaRecord> hawalaRecords = [];
List<WorkerSalary> workerSalaries = [];
List<MonthlySummary> monthlySummaries = [];
double currentMonthKhata = 0.0;
String bakeryName = "بلال احمد نانوایي";
String appUser = "Najibazizi"; 
String appPin = "4717"; 
Map<String, double> otherExpensesMap = {'کرایه': 0.0, 'لایسنس': 0.0, 'د بریښنا بل': 0.0, 'د اوبو بل': 0.0, 'د خونې لګښت': 0.0, 'ویزې نوي کول': 0.0, 'نور': 0.0};

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Serif'), home: const Directionality(textDirection: TextDirection.rtl, child: LoginPage()));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _uC = TextEditingController(), _pC = TextEditingController();
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFFDF5E6), body: SingleChildScrollView(child: Column(children: [Container(width: double.infinity, height: 250, decoration: const BoxDecoration(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)), image: DecorationImage(image: AssetImage('assets/header_banner.png'), fit: BoxFit.cover))), const SizedBox(height: 40), Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("کارن نوم", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10), TextField(controller: _uC, decoration: InputDecoration(prefixIcon: const Icon(Icons.person), hintText: "نوم ولیکئ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 20), const Text("پین کوډ", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10), TextField(controller: _pC, obscureText: true, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock), hintText: "کوډ ولیکئ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 40), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () { if (_uC.text == appUser && _pC.text == appPin) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage())); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("غلط معلومات!"), backgroundColor: Colors.red)); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("ننوځئ (Login)", style: TextStyle(color: Colors.white, fontSize: 18))))]))])));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0, _personalIndex = 0, _appMode = 0;
  final TextEditingController _khataC = TextEditingController(), _sC = TextEditingController(), _eA = TextEditingController(), _eR = TextEditingController(), _aQ = TextEditingController(), _aP = TextEditingController(), _gQ = TextEditingController(), _gP = TextEditingController();

  @override void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        final String? r = prefs.getString('bakery_records'); if (r != null) allRecords = (json.decode(r) as List).map((i) => BakeryRecord.fromJson(i)).toList();
        final String? pr = prefs.getString('personal_records'); if (pr != null) personalRecords = (json.decode(pr) as List).map((i) => PersonalRecord.fromJson(i)).toList();
        final String? dr = prefs.getString('debt_records'); if (dr != null) debtRecords = (json.decode(dr) as List).map((i) => DebtRecord.fromJson(i)).toList();
        final String? hr = prefs.getString('hawala_records'); if (hr != null) hawalaRecords = (json.decode(hr) as List).map((i) => HawalaRecord.fromJson(i)).toList();
        final String? s = prefs.getString('worker_salaries'); if (s != null) workerSalaries = (json.decode(s) as List).map((i) => WorkerSalary.fromJson(i)).toList();
        final String? o = prefs.getString('other_expenses'); if (o != null) (json.decode(o) as Map).forEach((k, v) { if (otherExpensesMap.containsKey(k)) otherExpensesMap[k] = (v as num).toDouble(); });
        final String? a = prefs.getString('monthly_summaries'); if (a != null) monthlySummaries = (json.decode(a) as List).map((i) => MonthlySummary.fromJson(i)).toList();
        currentMonthKhata = prefs.getDouble('current_khata') ?? 0.0; _khataC.text = currentMonthKhata == 0.0 ? "" : currentMonthKhata.toString();
        bakeryName = prefs.getString('bakery_name') ?? "بلال احمد نانوایي";
        appUser = prefs.getString('app_user') ?? "Najibazizi"; appPin = prefs.getString('app_pin') ?? "4717";
      });
    } catch (e) { debugPrint("Error loading data: $e"); }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bakery_records', json.encode(allRecords.map((r) => r.toJson()).toList()));
    await prefs.setString('personal_records', json.encode(personalRecords.map((r) => r.toJson()).toList()));
    await prefs.setString('debt_records', json.encode(debtRecords.map((r) => r.toJson()).toList()));
    await prefs.setString('hawala_records', json.encode(hawalaRecords.map((r) => r.toJson()).toList()));
    await prefs.setString('worker_salaries', json.encode(workerSalaries.map((s) => s.toJson()).toList()));
    await prefs.setString('other_expenses', json.encode(otherExpensesMap));
    await prefs.setString('monthly_summaries', json.encode(monthlySummaries.map((m) => m.toJson()).toList()));
    await prefs.setDouble('current_khata', currentMonthKhata); await prefs.setString('bakery_name', bakeryName);
    await prefs.setString('app_user', appUser); await prefs.setString('app_pin', appPin);
  }

  void _closeMonth(double s, double k, double d, double o, double w, double a, double g, double p) {
    String my = "${_getMonthName(DateTime.now().month)} ${DateTime.now().year}";
    setState(() { monthlySummaries.add(MonthlySummary(monthYear: my, totalSale: s, totalKhata: k, dailyExp: d, otherExp: o, workerBal: w, attaExp: a, gasExp: g, netProfit: p, dailyRecords: List.from(allRecords))); allRecords.clear(); currentMonthKhata = 0.0; _khataC.clear(); _saveData(); });
  }

  String _getMonthName(int m) => ["جنوري", "فبروري", "مارچ", "اپریل", "می", "جون", "جولای", "اګسټ", "سپټمبر", "اکټوبر", "نومبر", "دسمبر"][m - 1];

  @override Widget build(BuildContext context) {
    Widget body;
    if (_appMode == 0) {
      if (_currentIndex == 0) body = _buildEntryForm();
      else if (_currentIndex == 1) body = const HistoryPage();
      else if (_currentIndex == 2) body = ReportPage(onCloseMonth: _closeMonth, khataController: _khataC, onKhataChanged: (v) { currentMonthKhata = v; _saveData(); setState(() {}); });
      else if (_currentIndex == 3) body = ArchiveListPage(onUpdate: _saveData);
      else if (_currentIndex == 4) body = const YearlySummaryPage();
      else body = SettingsPage(onUpdate: () => setState(() { _saveData(); }));
    } else {
      if (_personalIndex == 0) body = PersonalAccountPage(onUpdate: _saveData);
      else if (_personalIndex == 1) body = PersonalActivitiesPage(onUpdate: _saveData);
      else if (_personalIndex == 2) body = PersonalDebtPage(onUpdate: _saveData);
      else body = HawalaPage(onUpdate: _saveData);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(backgroundColor: _appMode == 0 ? Colors.blue[800] : Colors.teal[800], title: Text(_appMode == 0 ? bakeryName : "شخصي حساب", style: const TextStyle(color: Colors.white)), centerTitle: true, actions: [IconButton(icon: Icon(_appMode == 0 ? Icons.person_outline : Icons.store, color: Colors.white), onPressed: () => setState(() { _appMode = _appMode == 0 ? 1 : 0; _personalIndex = 0; }), tooltip: "بدلول")]),
      body: body,
      bottomNavigationBar: BottomNavigationBar(currentIndex: _appMode == 1 ? _personalIndex : _currentIndex, onTap: (i) => setState(() { if (_appMode == 0) _currentIndex = i; else _personalIndex = i; }), type: BottomNavigationBarType.fixed, selectedItemColor: _appMode == 0 ? Colors.blue[900] : Colors.teal[900], items: _appMode == 1 ? const [
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "حساب"),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "فعالیتونه"),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "قرضونه"),
        BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: "حواله")
      ] : const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "هوم"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "تاریخچه"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "راپور"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "ارشیف"),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "کلنی"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "ترتیبات")
      ]),
    );
  }

  Widget _buildEntryForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2, child: Padding(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_DateItem(label: "کال", value: DateTime.now().year.toString()), _DateItem(label: "میاشت", value: _getMonthName(DateTime.now().month)), _DateItem(label: "نېټه", value: DateTime.now().day.toString())]))),
      const SizedBox(height: 20),
      _InputCard(title: "ورځنی خرڅلاو", icon: Icons.trending_up, color: Colors.green, controller: _sC, hint: "مقدار ولیکئ"),
      const SizedBox(height: 20),
      Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2, child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [Row(children: [Icon(Icons.payments, color: Colors.red[400]), const SizedBox(width: 10), const Text("ورځنی مصرف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), const SizedBox(height: 15), Row(children: [Expanded(child: TextField(controller: _eA, decoration: InputDecoration(hintText: "پیسې", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: _eR, decoration: InputDecoration(hintText: "علت", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),])]))),
      const SizedBox(height: 20),
      _DoubleInputCard(title: "اوړه / پارسل", icon: Icons.bakery_dining, color: Colors.orange, controller1: _aQ, hint1: "تعداد", controller2: _aP, hint2: "قیمت"),
      const SizedBox(height: 20),
      _DoubleInputCard(title: "ګاز / سلنډر", icon: Icons.gas_meter, color: Colors.blue, controller1: _gQ, hint1: "تعداد", controller2: _gP, hint2: "قیمت"),
      const SizedBox(height: 30),
      SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () { if (_sC.text.isEmpty) return; setState(() { allRecords.add(BakeryRecord(date: "${DateTime.now().day} ${_getMonthName(DateTime.now().month)}", sale: _sC.text, expenseAmount: _eA.text, expenseReason: _eR.text, attaQty: _aQ.text, attaPrice: _aP.text, gasQty: _gQ.text, gasPrice: _gP.text, timestamp: TimeOfDay.now().format(context))); _saveData(); _sC.clear(); _eA.clear(); _eR.clear(); _aQ.clear(); _aP.clear(); _gQ.clear(); _gP.clear(); }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ریکارډ اضافه شو!"), backgroundColor: Colors.green)); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("ریکارډ اضافه کړه", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 20),
      InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SalaryPage())), child: const _BrownButton(title: "د کارګرانو معاشونه", icon: Icons.people)),
      const SizedBox(height: 15),
      InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const OtherExpensesPage())), child: const _BrownButton(title: "نور لګښتونه", icon: Icons.payments))
    ]));
  }
}

// --- صفحات ---
class HistoryPage extends StatelessWidget { const HistoryPage({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.blue[800], title: const Text("ټول ورځني ریکارډونه", style: TextStyle(color: Colors.white)), centerTitle: true), body: Column(children: [const Padding(padding: EdgeInsets.all(10), child: Text("ټول ورځني ریکارډونه", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), Expanded(child: _buildRecordsTable(allRecords))])); }

class YearlySummaryPage extends StatelessWidget {
  const YearlySummaryPage({super.key});
  @override Widget build(BuildContext context) {
    double ts = 0, tk = 0, te = 0, np = 0;
    for (var m in monthlySummaries) { ts += m.totalSale; tk += m.totalKhata; te += (m.dailyExp + m.otherExp + m.workerBal + m.attaExp + m.gasExp); np += m.netProfit; }
    double ap = monthlySummaries.isEmpty ? 0 : np / monthlySummaries.length;
    return Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.blue[800], title: const Text("کلنی راپور", style: TextStyle(color: Colors.white)), centerTitle: true), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [const Text("د کال مجموعي راپور", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)), const SizedBox(height: 20), _ReportCard(title: "د کال ټوله دنده", value: ts.toStringAsFixed(2), icon: Icons.trending_up, color: Colors.green), _ReportCard(title: "د کال ټوله خاټه", value: tk.toStringAsFixed(2), icon: Icons.add_card, color: Colors.teal), _ReportCard(title: "د کال ټوټل مصرفونه", value: te.toStringAsFixed(2), icon: Icons.payments, color: Colors.red), const Divider(height: 40), _ReportCard(title: "د کال ټوله خالصه ګټه", value: np.toStringAsFixed(2), icon: Icons.account_balance, color: Colors.blue), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("د میاشتې اوسط ګټه:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("${ap.toStringAsFixed(2)} AED", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))]))])));
  }
}

class ArchiveListPage extends StatefulWidget {
  final VoidCallback onUpdate; const ArchiveListPage({super.key, required this.onUpdate});
  @override State<ArchiveListPage> createState() => _ArchiveListPageState();
}
class _ArchiveListPageState extends State<ArchiveListPage> {
  @override Widget build(BuildContext context) {
    if (monthlySummaries.isEmpty) return const Center(child: Text("تر اوسه ارشیف نشته."));
    return Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.blue[800], title: const Text("ارشیف", style: TextStyle(color: Colors.white)), centerTitle: true), body: ListView.builder(itemCount: monthlySummaries.length, itemBuilder: (c, i) {
        final summary = monthlySummaries[i];
        return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 2, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MonthlyDetailPage(summary: summary))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.folder_shared, color: Colors.brown), const SizedBox(width: 10), Text(summary.monthYear, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]), IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => setState(() { monthlySummaries.removeAt(i); widget.onUpdate(); }))]), const Divider(), _SmallReportRow(title: "ټول پلور:", value: summary.totalSale.toStringAsFixed(2), color: Colors.green), _SmallReportRow(title: "ټوله خاټه:", value: summary.totalKhata.toStringAsFixed(2), color: Colors.teal), _SmallReportRow(title: "ورځني مصرفونه:", value: summary.dailyExp.toStringAsFixed(2), color: Colors.red), _SmallReportRow(title: "نور لګښتونه:", value: summary.otherExp.toStringAsFixed(2), color: Colors.orange), _SmallReportRow(title: "د معاشونو حساب:", value: summary.workerBal.toStringAsFixed(2), color: Colors.deepPurple), _SmallReportRow(title: "د اوړو لګښت:", value: summary.attaExp.toStringAsFixed(2), color: Colors.brown), _SmallReportRow(title: "د ګازو لګښت:", value: summary.gasExp.toStringAsFixed(2), color: Colors.blueAccent), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("خالصه ګټه:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), Text("${summary.netProfit.toStringAsFixed(2)} AED", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))])]))));
    }));
  }
}

class MonthlyDetailPage extends StatelessWidget {
  final MonthlySummary summary; const MonthlyDetailPage({super.key, required this.summary});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.blue[800], title: Text(summary.monthYear, style: const TextStyle(color: Colors.white))), body: Directionality(textDirection: TextDirection.rtl, child: SingleChildScrollView(child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Column(children: [_ReportCard(title: "ټول پلور", value: summary.totalSale.toStringAsFixed(2), icon: Icons.trending_up, color: Colors.green), _ReportCard(title: "ټوله خاټه", value: summary.totalKhata.toStringAsFixed(2), icon: Icons.add_card, color: Colors.teal), _ReportCard(title: "ورځني مصرفونه", value: summary.dailyExp.toStringAsFixed(2), icon: Icons.payments, color: Colors.red), _ReportCard(title: "نور لګښتونه", value: summary.otherExp.toStringAsFixed(2), icon: Icons.account_balance_wallet, color: Colors.orange), _ReportCard(title: "د معاشونو پاتې حساب", value: summary.workerBal.toStringAsFixed(2), icon: Icons.people, color: Colors.deepPurple), _ReportCard(title: "د اوړو لګښت", value: summary.attaExp.toStringAsFixed(2), icon: Icons.bakery_dining, color: Colors.brown), _ReportCard(title: "د ګازو لګښت", value: summary.gasExp.toStringAsFixed(2), icon: Icons.gas_meter, color: Colors.blueAccent), const Divider(height: 30, thickness: 1), _ReportCard(title: "خالصه ګټه", value: summary.netProfit.toStringAsFixed(2), icon: Icons.account_balance, color: Colors.blue)])), const Text("ورځني جزیات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), _buildRecordsTable(summary.dailyRecords)]))));
}

class ReportPage extends StatelessWidget {
  final Function(double, double, double, double, double, double, double, double) onCloseMonth; final Function(double) onKhataChanged; final TextEditingController khataController;
  const ReportPage({super.key, required this.onCloseMonth, required this.onKhataChanged, required this.khataController});
  @override Widget build(BuildContext context) {
    double ts = 0, te = 0, taa = 0, tga = 0; for (var r in allRecords) { ts += double.tryParse(r.sale) ?? 0; te += double.tryParse(r.expenseAmount) ?? 0; taa += double.tryParse(r.attaPrice) ?? 0; tga += double.tryParse(r.gasPrice) ?? 0; }
    double oE = otherExpensesMap.values.fold(0, (a, b) => a + b); double wB = workerSalaries.fold(0, (a, b) => a + b.balance); double profit = (ts + currentMonthKhata) - te - oE - wB - taa - tga;
    return SingleChildScrollView(child: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _ReportCard(title: "ټول پلور", value: "${ts.toStringAsFixed(2)} AED", icon: Icons.trending_up, color: Colors.green),
        Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0x1A009688), child: Icon(Icons.add_card, color: Colors.teal)), title: const Text("ټوله خاټه", style: TextStyle(fontWeight: FontWeight.bold)), trailing: SizedBox(width: 100, child: TextField(controller: khataController, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "0.00"), keyboardType: TextInputType.number, onChanged: (v) => onKhataChanged(double.tryParse(v) ?? 0.0))))),
        _ReportCard(title: "ورځني مصرفونه", value: "${te.toStringAsFixed(2)} AED", icon: Icons.payments, color: Colors.red),
        _ReportCard(title: "نور لګښتونه", value: "${oE.toStringAsFixed(2)} AED", icon: Icons.account_balance_wallet, color: Colors.orange),
        _ReportCard(title: "د معاشونو پاتې حساب", value: "${wB.toStringAsFixed(2)} AED", icon: Icons.people, color: Colors.deepPurple),
        _ReportCard(title: "د اوړو لګښت", value: "${taa.toStringAsFixed(2)} AED", icon: Icons.bakery_dining, color: Colors.brown),
        _ReportCard(title: "د ګازو لګښت", value: "${tga.toStringAsFixed(2)} AED", icon: Icons.gas_meter, color: Colors.blueAccent),
        const Divider(height: 30, thickness: 1),
        _ReportCard(title: "خالصه ګټه", value: "${profit.toStringAsFixed(2)} AED", icon: Icons.account_balance, color: Colors.blue),
      ])),
      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("د میاشتې ورځني جزیات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      _buildRecordsTable(allRecords),
      Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () => onCloseMonth(ts, currentMonthKhata, te, oE, wB, taa, tga, profit), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]), child: const Text("میاشت بنده کړه او ارشیف کړه", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
    ]));
  }
}

class SalaryPage extends StatefulWidget { const SalaryPage({super.key}); @override State<SalaryPage> createState() => _SalaryPageState(); }
class _SalaryPageState extends State<SalaryPage> { 
  final _nC = TextEditingController(), _sC = TextEditingController(), _rC = TextEditingController(); 
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.blue[800], title: const Text("معاشونه", style: TextStyle(color: Colors.white))), body: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: _nC, textAlign: TextAlign.right, decoration: InputDecoration(hintText: "نوم", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: _rC, textAlign: TextAlign.right, decoration: InputDecoration(hintText: "ترلاسه شوې", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: _sC, textAlign: TextAlign.right, decoration: InputDecoration(hintText: "معاش", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number))]), const SizedBox(height: 15), ElevatedButton(onPressed: () { if (_nC.text.isEmpty) return; setState(() { workerSalaries.add(WorkerSalary(name: _nC.text, salary: double.tryParse(_sC.text) ?? 0, received: double.tryParse(_rC.text) ?? 0)); }); }, child: const Text("اضافه کړه"))])), Expanded(child: ListView.builder(itemCount: workerSalaries.length, itemBuilder: (c, i) => ListTile(leading: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => workerSalaries.removeAt(i))), title: Text(workerSalaries[i].name, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("پاتې: ${workerSalaries[i].balance}", textAlign: TextAlign.right))))])); 
}

class OtherExpensesPage extends StatefulWidget { const OtherExpensesPage({super.key}); @override State<OtherExpensesPage> createState() => _OtherExpensesPageState(); }
class _OtherExpensesPageState extends State<OtherExpensesPage> { 
  final Map<String, TextEditingController> _controllers = {}; 
  @override void initState() { super.initState(); otherExpensesMap.forEach((k, v) => _controllers[k] = TextEditingController(text: v.toString())); } 
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.blue[800], title: const Text("نور لګښتونه", style: TextStyle(color: Colors.white))), body: Column(children: [Expanded(child: ListView(padding: const EdgeInsets.all(16), children: _controllers.entries.map((e) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), child: Row(children: [Expanded(flex: 3, child: TextField(controller: e.value, textAlign: TextAlign.center, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "0.00", border: InputBorder.none))), const VerticalDivider(), Expanded(flex: 2, child: Text(e.key, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))],)))).toList())), Container(width: double.infinity, padding: const EdgeInsets.all(20), color: Colors.lightBlue[100], child: Text("مجموعه: ${_controllers.values.fold(0.0, (s, c) => s + (double.tryParse(c.text) ?? 0)).toStringAsFixed(2)} AED", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), ElevatedButton(onPressed: () { _controllers.forEach((k, c) => otherExpensesMap[k] = double.tryParse(c.text) ?? 0.0); Navigator.pop(context); }, child: const Text("خوندي کړه"))])); 
}

class PersonalAccountPage extends StatefulWidget {
  final VoidCallback onUpdate;
  const PersonalAccountPage({super.key, required this.onUpdate});
  @override State<PersonalAccountPage> createState() => _PersonalAccountPageState();
}
class _PersonalAccountPageState extends State<PersonalAccountPage> {
  final TextEditingController _tC = TextEditingController(), _aC = TextEditingController();
  String _selectedType = 'income';
  @override Widget build(BuildContext context) {
    double tI = 0, tE = 0; for (var r in personalRecords) { double a = double.tryParse(r.amount) ?? 0; if (r.type == 'income') tI += a; else tE += a; }
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [Expanded(child: _SummaryBox(title: "ټول درامد", value: tI.toStringAsFixed(2), color: Colors.green)), const SizedBox(width: 10), Expanded(child: _SummaryBox(title: "ټول مصرف", value: tE.toStringAsFixed(2), color: Colors.red))]),
      const SizedBox(height: 10), Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(15)), child: Column(children: [const Text("پاتې سپما"), Text("${(tI-tE).toStringAsFixed(2)} AED", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal))])),
      const SizedBox(height: 20), Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        const Text("نوی فعالیت اضافه کړئ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextField(controller: _tC, decoration: const InputDecoration(labelText: "تفصیل")), TextField(controller: _aC, decoration: const InputDecoration(labelText: "مقدار"), keyboardType: TextInputType.number),
        Row(children: [Expanded(child: RadioListTile(title: const Text("درامد"), value: 'income', groupValue: _selectedType, onChanged: (v) => setState(() => _selectedType = v.toString()))), Expanded(child: RadioListTile(title: const Text("مصرف"), value: 'expense', groupValue: _selectedType, onChanged: (v) => setState(() => _selectedType = v.toString())))]),
        ElevatedButton(onPressed: () { if (_tC.text.isEmpty || _aC.text.isEmpty) return; setState(() { personalRecords.insert(0, PersonalRecord(date: "${DateTime.now().day}/${DateTime.now().month}", title: _tC.text, amount: _aC.text, type: _selectedType)); }); widget.onUpdate(); _tC.clear(); _aC.clear(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]), child: const Text("ثبت کړه", style: TextStyle(color: Colors.white)))
      ])))
    ]));
  }
}

class PersonalActivitiesPage extends StatelessWidget {
  final VoidCallback onUpdate; const PersonalActivitiesPage({super.key, required this.onUpdate});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.teal[800], title: const Text("وروستي فعالیتونه")), body: ListView.builder(itemCount: personalRecords.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(8), child: ListTile(leading: CircleAvatar(backgroundColor: personalRecords[i].type == 'income' ? Colors.green[100] : Colors.red[100], child: Icon(personalRecords[i].type == 'income' ? Icons.arrow_downward : Icons.arrow_upward, color: personalRecords[i].type == 'income' ? Colors.green : Colors.red)), title: Text(personalRecords[i].title), subtitle: Text(personalRecords[i].date), trailing: Text(personalRecords[i].amount, style: TextStyle(color: personalRecords[i].type == 'income' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)), onLongPress: () { personalRecords.removeAt(i); onUpdate(); (context as Element).markNeedsBuild(); }))));
}

class PersonalDebtPage extends StatefulWidget {
  final VoidCallback onUpdate; const PersonalDebtPage({super.key, required this.onUpdate});
  @override State<PersonalDebtPage> createState() => _PersonalDebtPageState();
}
class _PersonalDebtPageState extends State<PersonalDebtPage> {
  final TextEditingController _nC = TextEditingController(), _tC = TextEditingController(), _pC = TextEditingController(), _rC = TextEditingController();
  String _mode = 'to_me';
  void _editDebt(int index, List<DebtRecord> filteredList) {
    final originalIndex = debtRecords.indexOf(filteredList[index]);
    final r = debtRecords[originalIndex];
    final TextEditingController nameC = TextEditingController(text: r.name), totalC = TextEditingController(text: r.totalAmount), paidC = TextEditingController(text: r.paidAmount), reasonC = TextEditingController(text: r.reason);
    showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: const Text("اصلاحول"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameC, decoration: const InputDecoration(labelText: "نوم")), TextField(controller: totalC, decoration: const InputDecoration(labelText: "مقدار"), keyboardType: TextInputType.number), TextField(controller: paidC, decoration: const InputDecoration(labelText: "وصول شوې"), keyboardType: TextInputType.number), TextField(controller: reasonC, decoration: const InputDecoration(labelText: "وجه"))])), actions: [ElevatedButton(onPressed: () { setState(() { debtRecords[originalIndex] = DebtRecord(date: r.date, name: nameC.text, totalAmount: totalC.text, paidAmount: paidC.text, reason: reasonC.text, debtType: r.debtType); }); widget.onUpdate(); Navigator.pop(ctx); }, child: const Text("خوندي"))])));
  }
  @override Widget build(BuildContext context) {
    List<DebtRecord> filtered = debtRecords.where((r) => r.debtType == _mode).toList();
    double sumT = 0, sumP = 0; for (var r in filtered) { sumT += double.tryParse(r.totalAmount) ?? 0; sumP += double.tryParse(r.paidAmount) ?? 0; }
    return Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.teal[800], title: const Text("قرضونه")), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [Expanded(child: _DebtModeBtn(label: "زما طلب", isSelected: _mode == 'to_me', color: Colors.green[700]!, onTap: () => setState(() => _mode = 'to_me'))), const SizedBox(width: 10), Expanded(child: _DebtModeBtn(label: "زما قرض", isSelected: _mode == 'on_me', color: Colors.red[700]!, onTap: () => setState(() => _mode = 'on_me')))]),
      const SizedBox(height: 15), Row(children: [Expanded(child: _SummaryBox(title: "ټول ټوټل", value: sumT.toStringAsFixed(2), color: Colors.blue[900]!)), Expanded(child: _SummaryBox(title: "ټول وصول", value: sumP.toStringAsFixed(2), color: Colors.green[900]!)), Expanded(child: _SummaryBox(title: "ټول پاتې", value: (sumT-sumP).toStringAsFixed(2), color: Colors.red[900]!))]),
      Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _nC, decoration: const InputDecoration(labelText: "نوم")),
        Row(children: [Expanded(child: TextField(controller: _tC, decoration: const InputDecoration(labelText: "مقدار"), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: _rC, decoration: const InputDecoration(labelText: "وجه")))]),
        const SizedBox(height: 10), ElevatedButton(onPressed: () { if (_nC.text.isEmpty) return; setState(() { debtRecords.insert(0, DebtRecord(date: "${DateTime.now().day}/${DateTime.now().month}", name: _nC.text, totalAmount: _tC.text, paidAmount: "0", reason: _rC.text, debtType: _mode)); }); widget.onUpdate(); _nC.clear(); _tC.clear(); _rC.clear(); }, child: const Text("پور ثبت کړه"))
      ]))),
      const SizedBox(height: 15), SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(_mode == 'to_me' ? Colors.green[800] : Colors.red[800]), columns: const [DataColumn(label: Text("نېټه", style: TextStyle(color: Colors.white))), DataColumn(label: Text("نوم", style: TextStyle(color: Colors.white))), DataColumn(label: Text("وجه", style: TextStyle(color: Colors.white))), DataColumn(label: Text("پاتې", style: TextStyle(color: Colors.white))), DataColumn(label: Text("تغیر", style: TextStyle(color: Colors.white)))], rows: List.generate(filtered.length, (i) => DataRow(cells: [DataCell(Text(filtered[i].date)), DataCell(Text(filtered[i].name)), DataCell(Text(filtered[i].reason)), DataCell(Text(filtered[i].remaining.toStringAsFixed(2))), DataCell(IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _editDebt(debtRecords.indexOf(filtered[i]), filtered)))]))))
    ])));
  }
}

class HawalaPage extends StatefulWidget {
  final VoidCallback onUpdate; const HawalaPage({super.key, required this.onUpdate});
  @override State<HawalaPage> createState() => _HawalaPageState();
}
class _HawalaPageState extends State<HawalaPage> {
  final TextEditingController _sC = TextEditingController(), _rC = TextEditingController(), _aC = TextEditingController();
  @override Widget build(BuildContext context) {
    double total = hawalaRecords.fold(0, (sum, r) => sum + (double.tryParse(r.amount) ?? 0));
    return Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.teal[800], title: const Text("حواله")), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("د حوالې صفحه", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15), _SummaryBox(title: "ټولې حوالې", value: total.toStringAsFixed(2), color: Colors.blue),
      Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _sC, decoration: const InputDecoration(labelText: "لیږونکی")), TextField(controller: _rC, decoration: const InputDecoration(labelText: "ترلاسه کونکی")),
        TextField(controller: _aC, decoration: const InputDecoration(labelText: "مقدار"), keyboardType: TextInputType.number),
        SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: () { if (_sC.text.isEmpty || _aC.text.isEmpty) return; setState(() { hawalaRecords.insert(0, HawalaRecord(date: "${DateTime.now().day}/${DateTime.now().month}", sender: _sC.text, receiver: _rC.text, amount: _aC.text, code: "", status: "pending")); }); widget.onUpdate(); _sC.clear(); _rC.clear(); _aC.clear(); }, child: const Text("حواله ثبت کړه")))
      ]))),
      const SizedBox(height: 15), ...List.generate(hawalaRecords.length, (i) => Card(child: ListTile(title: Text("${hawalaRecords[i].sender} -> ${hawalaRecords[i].receiver}"), trailing: Text("${hawalaRecords[i].amount} AED"), subtitle: Text(hawalaRecords[i].date))))
    ])));
  }
}

class SettingsPage extends StatefulWidget {
  final VoidCallback onUpdate; const SettingsPage({super.key, required this.onUpdate});
  @override State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: Colors.blue[800], title: const Text("ترتیبات", style: TextStyle(color: Colors.white)), centerTitle: true), body: ListView(padding: const EdgeInsets.all(16), children: [
    _buildSectionTitle("پروفایل او امنیت"),
    _buildSettingItem(context, "د نانوایۍ نوم", bakeryName, Icons.store, () => _showEditDialog(context, "نوم", bakeryName, (v) { bakeryName = v; widget.onUpdate(); })),
    _buildSettingItem(context, "د کارونکي نوم", appUser, Icons.person, () => _showEditDialog(context, "نوم", appUser, (v) { appUser = v; widget.onUpdate(); })),
    _buildSettingItem(context, "پین کوډ (PIN)", "****", Icons.lock, () => _showEditDialog(context, "کوډ", appPin, (v) { appPin = v; widget.onUpdate(); })),
    const SizedBox(height: 20),
    _buildSectionTitle("د معلوماتو مدیریت"),
    _buildSettingItem(context, "بک اپ په ګوګل ډرایو کې", "اوسني معلومات خوندي کړئ", Icons.cloud_upload, () {}),
    _buildSettingItem(context, "بیا ترلاسه کول له ډرایو", "پخواني معلومات راوړئ", Icons.cloud_download, () {}),
    _buildSettingItem(context, "د تاریخچې پاکول", "ټول ورځني ریکارډونه", Icons.delete_sweep, () => _showDeleteConfirm(context, "تاریخچه", () { allRecords.clear(); widget.onUpdate(); }), color: Colors.red),
    _buildSettingItem(context, "د ارشیف پاکول", "ټول میاشتني راپورونه", Icons.archive, () => _showDeleteConfirm(context, "ارشیف", () { monthlySummaries.clear(); widget.onUpdate(); }), color: Colors.red),
    const SizedBox(height: 20),
    _buildSectionTitle("نور"),
    _buildSettingItem(context, "د اپلیکیشن په اړه", "نجیب الله عزیزی", Icons.info, () {
      showAboutDialog(context: context, applicationName: bakeryName, applicationVersion: "1.0.0", applicationIcon: const Icon(Icons.bakery_dining, size: 50, color: Colors.brown), children: [const Text("دا افلیکیشن زما (نجیب الله عزیزی) له طرفه د نانوایانو لپاره جوړ شوی تر څو د دوکان په حسابي کې ورته اسانتیا جوړه وې.")]);
    }),
  ]));
}

// --- کومکي ویجټونه ---
Widget _buildRecordsTable(List<BakeryRecord> records) {
  if (records.isEmpty) return const Center(child: Text("هیڅ ریکارډ نشته."));
  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(Colors.blue[900]), columns: const [
    DataColumn(label: Text("نېټه", style: TextStyle(color: Colors.white))),
    DataColumn(label: Text("وخت", style: TextStyle(color: Colors.white))),
    DataColumn(label: Text("پلور", style: TextStyle(color: Colors.white))),
    DataColumn(label: Text("مصرف", style: TextStyle(color: Colors.white))),
    DataColumn(label: Text("اوړه", style: TextStyle(color: Colors.white))),
    DataColumn(label: Text("ګاز", style: TextStyle(color: Colors.white))),
  ], rows: records.map((r) => DataRow(cells: [
    DataCell(Text(r.date)), DataCell(Text(r.timestamp)), DataCell(Text(r.sale)), DataCell(Text(r.expenseAmount)), DataCell(Text(r.attaPrice)), DataCell(Text(r.gasPrice))
  ])).toList()));
}
class _SummaryBox extends StatelessWidget { final String title, value; final Color color; const _SummaryBox({required this.title, required this.value, required this.color}); @override Widget build(BuildContext context) => Column(children: [Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]); }
class _DebtModeBtn extends StatelessWidget { final String label; final bool isSelected; final Color color; final VoidCallback onTap; const _DebtModeBtn({required this.label, required this.isSelected, required this.color, required this.onTap}); @override Widget build(BuildContext context) => Expanded(child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: isSelected ? color : Colors.grey[300], foregroundColor: isSelected ? Colors.white : Colors.black), child: Text(label, style: const TextStyle(fontSize: 12)))); }
class _ModeButton extends StatelessWidget { final IconData icon; final String label; final bool isSelected; final VoidCallback onTap; const _ModeButton({required this.icon, required this.label, required this.isSelected, required this.onTap}); @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isSelected ? Colors.blue[100] : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Column(children: [Icon(icon, color: isSelected ? Colors.blue[900] : Colors.grey[600]), Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.blue[900] : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : null))]))); }
class _ReportCard extends StatelessWidget { final String title, value; final IconData icon; final Color color; const _ReportCard({required this.title, required this.value, required this.icon, required this.color}); @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)))); }
class _DateItem extends StatelessWidget { final String label, value; const _DateItem({required this.label, required this.value}); @override Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]); }
class _InputCard extends StatelessWidget { final String title, hint; final IconData icon; final Color color; final TextEditingController controller; const _InputCard({required this.title, required this.icon, required this.color, required this.controller, required this.hint}); @override Widget build(BuildContext context) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2, child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), const SizedBox(height: 10), TextField(controller: controller, textAlign: TextAlign.right, decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number)]))); }
class _DoubleInputCard extends StatelessWidget { final String title, hint1, hint2; final IconData icon; final Color color; final TextEditingController controller1, controller2; const _DoubleInputCard({required this.title, required this.icon, required this.color, required this.controller1, required this.hint1, required this.controller2, required this.hint2}); @override Widget build(BuildContext context) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2, child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: controller1, decoration: InputDecoration(hintText: hint1, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: controller2, decoration: InputDecoration(hintText: hint2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number))])]))); }
class _BrownButton extends StatelessWidget { final String title; final IconData icon; const _BrownButton({required this.title, required this.icon}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 15), Text(title, style: const TextStyle(color: Colors.white, fontSize: 18))]), const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18)])); }
class _SmallReportRow extends StatelessWidget { final String title, value; final Color color; const _SmallReportRow({required this.title, required this.value, required this.color}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold))])); }
Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)));
Widget _buildSettingItem(BuildContext context, String title, String sub, IconData icon, VoidCallback tap, {Color? color}) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(icon, color: color ?? Colors.blue[800]), title: Text(title), subtitle: Text(sub), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: tap));
void _showEditDialog(BuildContext context, String title, String current, Function(String) onSave) { TextEditingController c = TextEditingController(text: current); showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: Text("بدلول: $title"), content: TextField(controller: c, decoration: const InputDecoration(border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("لغوه کړه")), ElevatedButton(onPressed: () { onSave(c.text); Navigator.pop(ctx); }, child: const Text("خوندي کړه"))]))); }
void _showDeleteConfirm(BuildContext context, String target, VoidCallback onConfirm) { showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: const Text("تایید"), content: Text("ایا غواړئ ټول $target پاک کړئ؟"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("نه")), ElevatedButton(onPressed: () { onConfirm(); Navigator.pop(ctx); }, child: const Text("هو"))]))); }
