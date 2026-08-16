import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BakeryApp());
}

// --- ډیټا موډلونه ---
class BakeryRecord {
  final String date, sale, expenseAmount, expenseReason, attaQty, attaPrice, gasQty, gasPrice, timestamp;
  BakeryRecord({required this.date, required this.sale, required this.expenseAmount, required this.expenseReason, required this.attaQty, required this.attaPrice, required this.gasQty, required this.gasPrice, required this.timestamp});
  Map<String, dynamic> toJson() => {'date': date, 'sale': sale, 'expenseAmount': expenseAmount, 'expenseReason': expenseReason, 'attaQty': attaQty, 'attaPrice': attaPrice, 'gasQty': gasQty, 'gasPrice': gasPrice, 'timestamp': timestamp};
  factory BakeryRecord.fromJson(Map<String, dynamic> json) => BakeryRecord(date: json['date'], sale: json['sale'], expenseAmount: json['expenseAmount'], expenseReason: json['expenseReason'], attaQty: json['attaQty'], attaPrice: json['attaPrice'], gasQty: json['gasQty'], gasPrice: json['gasPrice'], timestamp: json['timestamp']);
}

class WorkerSalary {
  final String name; final double salary, received;
  WorkerSalary({required this.name, required this.salary, required this.received});
  double get balance => salary - received;
  Map<String, dynamic> toJson() => {'name': name, 'salary': salary, 'received': received};
  factory WorkerSalary.fromJson(Map<String, dynamic> json) => WorkerSalary(name: json['name'], salary: json['salary'], received: json['received']);
}

class MonthlySummary {
  final String monthYear;
  final double totalSale, totalKhata, dailyExp, otherExp, workerBal, attaExp, gasExp, netProfit;
  final List<BakeryRecord> dailyRecords;
  MonthlySummary({required this.monthYear, required this.totalSale, required this.totalKhata, required this.dailyExp, required this.otherExp, required this.workerBal, required this.attaExp, required this.gasExp, required this.netProfit, required this.dailyRecords});
  Map<String, dynamic> toJson() => {'monthYear': monthYear, 'totalSale': totalSale, 'totalKhata': totalKhata, 'dailyExp': dailyExp, 'otherExp': otherExp, 'workerBal': workerBal, 'attaExp': attaExp, 'gasExp': gasExp, 'netProfit': netProfit, 'dailyRecords': dailyRecords.map((r) => r.toJson()).toList()};
  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(monthYear: json['monthYear'], totalSale: json['totalSale'], totalKhata: json['totalKhata'] ?? 0.0, dailyExp: json['dailyExp'], otherExp: json['otherExp'], workerBal: json['workerBal'], attaExp: json['attaExp'], gasExp: json['gasExp'], netProfit: json['netProfit'], dailyRecords: (json['dailyRecords'] as List).map((r) => BakeryRecord.fromJson(r)).toList());
}

// --- عمومي متغیرونه ---
List<BakeryRecord> allRecords = [];
List<WorkerSalary> workerSalaries = [];
List<MonthlySummary> monthlySummaries = [];
double currentMonthKhata = 0.0;
String bakeryName = "بلال احمد نانوایي";
String appUser = "Najibazizi"; 
String appPin = "4717"; 
Map<String, double> otherExpensesMap = {'کرایه': 0.0, 'لایسنس': 0.0, 'د بریښنا بل': 0.0, 'د اوبو بل': 0.0, 'د خونې لګښت': 0.0, 'ویزې نوي کول': 0.0, 'نور': 0.0};

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Serif'), home: const Directionality(textDirection: TextDirection.rtl, child: LoginPage()));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _uC = TextEditingController(), _pC = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      body: SingleChildScrollView(
        child: Column(children: [
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 60), decoration: const BoxDecoration(color: Color(0xFF4E342E), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50))), child: const Column(children: [Icon(Icons.bakery_dining, size: 80, color: Colors.white), SizedBox(height: 10), Text('Welcome to\nBelal Ahmed Bakery', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))])),
          const SizedBox(height: 40),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("User Name", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10), TextField(controller: _uC, decoration: InputDecoration(prefixIcon: const Icon(Icons.person), hintText: "Enter user name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            const Text("PIN Number", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10), TextField(controller: _pC, obscureText: true, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock), hintText: "Enter PIN", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () { if (_uC.text == appUser && _pC.text == appPin) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage())); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("غلط معلومات!"), backgroundColor: Colors.red)); } }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4E342E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18)))),
          ])),
          const SizedBox(height: 20),
          const Padding(padding: EdgeInsets.all(20), child: Image(image: NetworkImage('https://img.freepik.com/free-photo/delicious-bread-basket_23-2148842106.jpg'))),
        ]),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TextEditingController _khataC = TextEditingController();
  final TextEditingController _sC = TextEditingController(), _eA = TextEditingController(), _eR = TextEditingController(), _aQ = TextEditingController(), _aP = TextEditingController(), _gQ = TextEditingController(), _gP = TextEditingController();

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final String? r = prefs.getString('bakery_records');
      if (r != null) allRecords = (json.decode(r) as List).map((i) => BakeryRecord.fromJson(i)).toList();
      final String? s = prefs.getString('worker_salaries');
      if (s != null) workerSalaries = (json.decode(s) as List).map((i) => WorkerSalary.fromJson(i)).toList();
      final String? o = prefs.getString('other_expenses');
      if (o != null) (json.decode(o) as Map).forEach((k, v) { if (otherExpensesMap.containsKey(k)) otherExpensesMap[k] = v.toDouble(); });
      final String? a = prefs.getString('monthly_summaries');
      if (a != null) monthlySummaries = (json.decode(a) as List).map((i) => MonthlySummary.fromJson(i)).toList();
      currentMonthKhata = prefs.getDouble('current_khata') ?? 0.0;
      _khataC.text = currentMonthKhata == 0.0 ? "" : currentMonthKhata.toString();
      bakeryName = prefs.getString('bakery_name') ?? "بلال احمد نانوایي";
      appUser = prefs.getString('app_user') ?? "Najibazizi";
      appPin = prefs.getString('app_pin') ?? "4717";
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bakery_records', json.encode(allRecords.map((r) => r.toJson()).toList()));
    await prefs.setString('worker_salaries', json.encode(workerSalaries.map((s) => s.toJson()).toList()));
    await prefs.setString('other_expenses', json.encode(otherExpensesMap));
    await prefs.setString('monthly_summaries', json.encode(monthlySummaries.map((m) => m.toJson()).toList()));
    await prefs.setDouble('current_khata', currentMonthKhata);
    await prefs.setString('bakery_name', bakeryName);
    await prefs.setString('app_user', appUser);
    await prefs.setString('app_pin', appPin);
  }

  void _closeMonth(double s, double k, double d, double o, double w, double a, double g, double p) {
    String my = "${_getMonthName(DateTime.now().month)} ${DateTime.now().year}";
    setState(() {
      monthlySummaries.add(MonthlySummary(monthYear: my, totalSale: s, totalKhata: k, dailyExp: d, otherExp: o, workerBal: w, attaExp: a, gasExp: g, netProfit: p, dailyRecords: List.from(allRecords)));
      allRecords.clear(); currentMonthKhata = 0.0; _khataC.clear(); _saveData();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("د $my بشپړ راپور ارشیف شو!")));
  }

  String _getMonthName(int m) => ["جنوري", "فبروري", "مارچ", "اپریل", "می", "جون", "جولای", "اګسټ", "سپټمبر", "اکټوبر", "نومبر", "دسمبر"][m - 1];

  @override
  Widget build(BuildContext context) {
    Widget body = [_buildEntryForm(), const HistoryPage(), ReportPage(onCloseMonth: _closeMonth, khataController: _khataC, onKhataChanged: (v) { currentMonthKhata = v; _saveData(); setState(() {}); }), const AnnualReportPage(), SettingsPage(onUpdate: () => setState(() { _saveData(); }))][_currentIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(backgroundColor: const Color(0xFF4E342E), title: Text(_currentIndex == 4 ? "ترتیبات" : bakeryName, style: const TextStyle(color: Colors.white)), centerTitle: true),
      body: body,
      bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF4E342E), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "هوم"), BottomNavigationBarItem(icon: Icon(Icons.history), label: "تاریخچه"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "راپور"), BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "ارشیف"), BottomNavigationBarItem(icon: Icon(Icons.settings), label: "ترتیبات")]),
    );
  }

  Widget _buildEntryForm() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_DateItem(label: "نېټه", value: DateTime.now().day.toString()), _DateItem(label: "میاشت", value: _getMonthName(DateTime.now().month)), _DateItem(label: "کال", value: DateTime.now().year.toString())]))), const SizedBox(height: 15), _InputCard(title: "ورځنی خرڅلاو", icon: Icons.trending_up, color: Colors.green, controller: _sC, hint: "مقدار ولیکئ", unit: "AED"), const SizedBox(height: 15), Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [const Row(children: [Icon(Icons.payments, color: Colors.red), SizedBox(width: 10), Text("ورځنی مصرف", style: TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: _eA, decoration: const InputDecoration(hintText: "پیسې", border: OutlineInputBorder()), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: _eR, decoration: const InputDecoration(hintText: "علت", border: OutlineInputBorder()))),])]))), const SizedBox(height: 15), _DoubleInputCard(title: "اوړه / پارسل", icon: Icons.bakery_dining, color: Colors.orange, controller1: _aQ, hint1: "تعداد", controller2: _aP, hint2: "قیمت"), const SizedBox(height: 15), _DoubleInputCard(title: "ګاز / سلنډر", icon: Icons.gas_meter, color: Colors.blue, controller1: _gQ, hint1: "تعداد", controller2: _gP, hint2: "قیمت"), const SizedBox(height: 25), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () { if (_sC.text.isEmpty) return; setState(() { allRecords.add(BakeryRecord(date: "${DateTime.now().day} ${_getMonthName(DateTime.now().month)}", sale: _sC.text, expenseAmount: _eA.text, expenseReason: _eR.text, attaQty: _aQ.text, attaPrice: _aP.text, gasQty: _gQ.text, gasPrice: _gP.text, timestamp: TimeOfDay.now().format(context))); _saveData(); _sC.clear(); _eA.clear(); _eR.clear(); _aQ.clear(); _aP.clear(); _gQ.clear(); _gP.clear(); }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ریکارډ اضافه شو!"), backgroundColor: Colors.green)); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("ریکارډ اضافه کړه", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))), const SizedBox(height: 20), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const Directionality(textDirection: TextDirection.rtl, child: SalaryPage()))), child: _BrownButton(title: "د کارګرانو معاشونه", icon: Icons.people)), const SizedBox(height: 15), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const Directionality(textDirection: TextDirection.rtl, child: OtherExpensesPage()))), child: _BrownButton(title: "نور لګښتونه", icon: Icons.payments))]));
  }
}

class SettingsPage extends StatelessWidget {
  final VoidCallback onUpdate;
  const SettingsPage({super.key, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle("پروفایل او امنیت"),
        _buildSettingItem(context, "د نانوایۍ نوم", bakeryName, Icons.store, () => _showEditDialog(context, "د نانوایۍ نوم", bakeryName, (v) { bakeryName = v; onUpdate(); })),
        _buildSettingItem(context, "د کارونکي نوم", appUser, Icons.person, () => _showEditDialog(context, "د کارونکي نوم", appUser, (v) { appUser = v; onUpdate(); })),
        _buildSettingItem(context, "پین کوډ (PIN)", "****", Icons.lock, () => _showEditDialog(context, "پین کوډ", appPin, (v) { appPin = v; onUpdate(); }, isNumber: true)),
        const SizedBox(height: 20),
        _buildSectionTitle("د معلوماتو مدیریت"),
        _buildSettingItem(context, "د تاریخچې پاکول", "ټول ورځني ریکارډونه", Icons.delete_sweep, () => _showDeleteConfirm(context, "تاریخچه", () { allRecords.clear(); onUpdate(); }), color: Colors.red),
        _buildSettingItem(context, "د ارشیف پاکول", "ټول میاشتني راپورونه", Icons.archive, () => _showDeleteConfirm(context, "ارشیف", () { monthlySummaries.clear(); onUpdate(); }), color: Colors.red),
        const SizedBox(height: 20),
        _buildSectionTitle("نور"),
        _buildSettingItem(context, "ژبه", "پښتو", Icons.language, () {}),
        _buildSettingItem(context, "د اپلیکیشن په اړه", "نجیب الله عزیزی", Icons.info, () => _showAbout(context)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))));
  Widget _buildSettingItem(BuildContext context, String title, String sub, IconData icon, VoidCallback tap, {Color? color}) => Card(child: ListTile(leading: Icon(icon, color: color ?? const Color(0xFF4E342E)), title: Text(title), subtitle: Text(sub), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: tap));

  void _showEditDialog(BuildContext context, String title, String current, Function(String) onSave, {bool isNumber = false}) {
    TextEditingController c = TextEditingController(text: current);
    showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: Text("بدلول: $title"), content: TextField(controller: c, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: const InputDecoration(border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("لغوه کړه")), ElevatedButton(onPressed: () { onSave(c.text); Navigator.pop(ctx); }, child: const Text("خوندي کړه"))])));
  }

  void _showDeleteConfirm(BuildContext context, String target, VoidCallback onConfirm) {
    showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: const Text("تایید"), content: Text("ایا تاسو ډاډه یاست چې غواړئ ټول $target پاک کړئ؟"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("نه")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { onConfirm(); Navigator.pop(ctx); }, child: const Text("هو، پاک یې کړه"))])));
  }

  void _showAbout(BuildContext context) => showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: const Text("د اپلیکیشن په اړه"), content: const Text("دا افلیکیشن زما (نجیب الله عزیزی) له طرفه د نانوایانو لپاره جوړ شوی تر څو د دوکان په حسابي کې ورته اسانتیا جوړه وې، که څه هم ما ‌‌ډیر زحمت پکښې ایستلی خو د خپلو هیوادوالو لپاره یې د ځان ویاړ کڼم."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("بندول"))])));
}

class ReportPage extends StatelessWidget {
  final Function(double, double, double, double, double, double, double, double) onCloseMonth;
  final Function(double) onKhataChanged;
  final TextEditingController khataController;
  const ReportPage({super.key, required this.onCloseMonth, required this.onKhataChanged, required this.khataController});
  @override
  Widget build(BuildContext context) {
    double ts = 0, te = 0, taa = 0, tga = 0;
    for (var r in allRecords) { ts += double.tryParse(r.sale) ?? 0; te += double.tryParse(r.expenseAmount) ?? 0; taa += double.tryParse(r.attaPrice) ?? 0; tga += double.tryParse(r.gasPrice) ?? 0; }
    double oE = otherExpensesMap.values.fold(0, (a, b) => a + b);
    double wB = workerSalaries.fold(0, (a, b) => a + b.balance);
    double profit = (ts + currentMonthKhata) - te - oE - wB - taa - tga;
    return SingleChildScrollView(child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Column(children: [_ReportCard(title: "ټول پلور", value: "${ts.toStringAsFixed(2)} AED", icon: Icons.trending_up, color: Colors.green), Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.1), child: const Icon(Icons.add_card, color: Colors.teal)), title: const Text("ټوله خاټه", style: TextStyle(fontWeight: FontWeight.bold)), trailing: SizedBox(width: 80, child: TextField(controller: khataController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "0.00"), onChanged: (v) => onKhataChanged(double.tryParse(v) ?? 0.0))))), _ReportCard(title: "ورځني مصرفونه", value: "${te.toStringAsFixed(2)} AED", icon: Icons.payments, color: Colors.red), _ReportCard(title: "نور لګښتونه", value: "${oE.toStringAsFixed(2)} AED", icon: Icons.account_balance_wallet, color: Colors.orange), _ReportCard(title: "د معاشونو پاتې حساب", value: "${wB.toStringAsFixed(2)} AED", icon: Icons.people, color: Colors.deepPurple), _ReportCard(title: "د اوړو لګښت", value: "${taa.toStringAsFixed(2)} AED", icon: Icons.bakery_dining, color: Colors.brown), _ReportCard(title: "د ګازو لګښت", value: "${tga.toStringAsFixed(2)} AED", icon: Icons.gas_meter, color: Colors.blueAccent), const Divider(height: 30, thickness: 2), _ReportCard(title: "خالصه ګټه", value: "${profit.toStringAsFixed(2)} AED", icon: Icons.account_balance, color: Colors.blue)])), const Text("د میاشتې ورځني جزیات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), _buildRecordsTable(allRecords), Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () => onCloseMonth(ts, currentMonthKhata, te, oE, wB, taa, tga, profit), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]), child: const Text("میاشت بنده کړه او ارشیف کړه", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))]));
  }
}

Widget _buildRecordsTable(List<BakeryRecord> records) {
  if (records.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("هیڅ ریکارډ نشته.")));
  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(const Color(0xFF4E342E)), columns: const [DataColumn(label: Text("نېټه", style: TextStyle(color: Colors.white))), DataColumn(label: Text("وخت", style: TextStyle(color: Colors.white))), DataColumn(label: Text("پلور", style: TextStyle(color: Colors.white))), DataColumn(label: Text("مصرف", style: TextStyle(color: Colors.white))), DataColumn(label: Text("اوړه", style: TextStyle(color: Colors.white))), DataColumn(label: Text("ګاز", style: TextStyle(color: Colors.white)))], rows: records.map((r) => DataRow(cells: [DataCell(Text(r.date)), DataCell(Text(r.timestamp)), DataCell(Text(r.sale)), DataCell(Text(r.expenseAmount)), DataCell(Text(r.attaPrice)), DataCell(Text(r.gasPrice))])).toList()));
}

class HistoryPage extends StatelessWidget { const HistoryPage({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), body: Column(children: [const Padding(padding: EdgeInsets.all(10), child: Text("ټول ورځني ریکارډونه", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), Expanded(child: _buildRecordsTable(allRecords))])); }
class AnnualReportPage extends StatelessWidget { const AnnualReportPage({super.key}); @override Widget build(BuildContext context) => monthlySummaries.isEmpty ? const Center(child: Text("تر اوسه ارشیف نشته.")) : ListView.builder(itemCount: monthlySummaries.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: const Icon(Icons.folder, color: Colors.brown), title: Text(monthlySummaries[i].monthYear, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("ګټه: ${monthlySummaries[i].netProfit.toStringAsFixed(2)} AED"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MonthlyDetailPage(summary: monthlySummaries[i])))))); }
class MonthlyDetailPage extends StatelessWidget { final MonthlySummary summary; const MonthlyDetailPage({super.key, required this.summary}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: const Color(0xFF4E342E), title: Text(summary.monthYear, style: const TextStyle(color: Colors.white))), body: Directionality(textDirection: TextDirection.rtl, child: SingleChildScrollView(child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Column(children: [_ReportCard(title: "ټول پلور", value: "${summary.totalSale} AED", icon: Icons.trending_up, color: Colors.green), _ReportCard(title: "ټوله خاټه", value: "${summary.totalKhata} AED", icon: Icons.add_card, color: Colors.teal), _ReportCard(title: "ورځني مصرفونه", value: "${summary.dailyExp} AED", icon: Icons.payments, color: Colors.red), _ReportCard(title: "نور لګښتونه", value: "${summary.otherExp} AED", icon: Icons.account_balance_wallet, color: Colors.orange), _ReportCard(title: "د معاشونو پاتې حساب", value: "${summary.workerBal} AED", icon: Icons.people, color: Colors.deepPurple), _ReportCard(title: "د اوړو لګښت", value: "${summary.attaExp} AED", icon: Icons.bakery_dining, color: Colors.brown), _ReportCard(title: "د ګازو لګښت", value: "${summary.gasExp} AED", icon: Icons.gas_meter, color: Colors.blueAccent), const Divider(height: 30, thickness: 2), _ReportCard(title: "خالصه ګټه", value: "${summary.netProfit} AED", icon: Icons.account_balance, color: Colors.blue)])), const Text("د میاشتې ورځني جزیات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), _buildRecordsTable(summary.dailyRecords)])))); }
class SalaryPage extends StatefulWidget { const SalaryPage({super.key}); @override State<SalaryPage> createState() => _SalaryPageState(); }
class _SalaryPageState extends State<SalaryPage> { final _nC = TextEditingController(), _sC = TextEditingController(), _rC = TextEditingController(); @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: const Color(0xFF4E342E), title: const Text("معاشونه", style: TextStyle(color: Colors.white))), body: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: _nC, decoration: const InputDecoration(labelText: "نوم", border: OutlineInputBorder())), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: _sC, decoration: const InputDecoration(labelText: "معاش", border: OutlineInputBorder()), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: _rC, decoration: const InputDecoration(labelText: "ترلاسه شوي", border: OutlineInputBorder()), keyboardType: TextInputType.number))]), ElevatedButton(onPressed: () { if (_nC.text.isEmpty) return; setState(() { workerSalaries.add(WorkerSalary(name: _nC.text, salary: double.tryParse(_sC.text) ?? 0, received: double.tryParse(_rC.text) ?? 0)); }); }, child: const Text("اضافه کړه"))])), Expanded(child: ListView.builder(itemCount: workerSalaries.length, itemBuilder: (c, i) => ListTile(title: Text(workerSalaries[i].name), subtitle: Text("پاتې: ${workerSalaries[i].balance}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => workerSalaries.removeAt(i))))))])); }
class OtherExpensesPage extends StatefulWidget { const OtherExpensesPage({super.key}); @override State<OtherExpensesPage> createState() => _OtherExpensesPageState(); }
class _OtherExpensesPageState extends State<OtherExpensesPage> { final Map<String, TextEditingController> _controllers = {}; @override void initState() { super.initState(); otherExpensesMap.forEach((k, v) => _controllers[k] = TextEditingController(text: v == 0.0 ? "" : v.toString())); } @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFFDF5E6), appBar: AppBar(backgroundColor: const Color(0xFF4E342E), title: const Text("نور لګښتونه", style: TextStyle(color: Colors.white))), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [..._controllers.entries.map((e) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(flex: 2, child: Text(e.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), Expanded(flex: 3, child: TextField(controller: e.value, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "0.00"), onChanged: (v) => setState(() {})))])))), const SizedBox(height: 20), Container(padding: const EdgeInsets.all(20), color: Colors.lightBlueAccent, alignment: Alignment.center, child: Text("مجموعه: ${_controllers.values.fold(0.0, (s, c) => s + (double.tryParse(c.text) ?? 0)).toStringAsFixed(2)} AED", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), const SizedBox(height: 20), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () async { _controllers.forEach((k, c) => otherExpensesMap[k] = double.tryParse(c.text) ?? 0.0); final prefs = await SharedPreferences.getInstance(); await prefs.setString('other_expenses', json.encode(otherExpensesMap)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("خوندي شو!"), backgroundColor: Colors.green)); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("خوندي کړه او راپور ته یې اضافه کړه", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))))]))); }

class _DateItem extends StatelessWidget { final String label, value; const _DateItem({required this.label, required this.value}); @override Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]); }
class _InputCard extends StatelessWidget { final String title, hint, unit; final IconData icon; final Color color; final TextEditingController controller; const _InputCard({required this.title, required this.icon, required this.color, required this.controller, required this.hint, required this.unit}); @override Widget build(BuildContext context) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 10), TextField(controller: controller, decoration: InputDecoration(hintText: hint, suffixText: unit, border: const OutlineInputBorder()), keyboardType: TextInputType.number)]))); }
class _DoubleInputCard extends StatelessWidget { final String title, hint1, hint2; final IconData icon; final Color color; final TextEditingController controller1, controller2; const _DoubleInputCard({required this.title, required this.icon, required this.color, required this.controller1, required this.hint1, required this.controller2, required this.hint2}); @override Widget build(BuildContext context) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: controller1, decoration: InputDecoration(hintText: hint1, border: const OutlineInputBorder()), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: controller2, decoration: InputDecoration(hintText: hint2, border: const OutlineInputBorder()), keyboardType: TextInputType.number))])]))); }
class _BrownButton extends StatelessWidget { final String title; final IconData icon; const _BrownButton({required this.title, required this.icon}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF4E342E), borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 15), Text(title, style: const TextStyle(color: Colors.white, fontSize: 18))]), const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18)])); }
class _ReportCard extends StatelessWidget { final String title, value; final IconData icon; final Color color; const _ReportCard({required this.title, required this.value, required this.icon, required this.color}); @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)))); }
