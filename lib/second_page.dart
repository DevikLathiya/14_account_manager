import 'package:account_manager/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/shape/gf_button_shape.dart';
import 'package:getwidget/types/gf_button_type.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';
import 'Controller Screen/GetXController.dart';
import 'package:path/path.dart';

class SecondPage extends StatefulWidget {
  static Database? database;

  const SecondPage({Key? key}) : super(key: key);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  MyController data = Get.put(MyController());
  TextEditingController _answer1 = TextEditingController();
  final TextEditingController _answer2 = TextEditingController();
  final TextEditingController _newpass = TextEditingController();

  var selectedindex = 0;
  String code = '';
  String password = '';
  Box box = Hive.box("Account");

  dataTable() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'AccountManager.db');

    SecondPage.database = await openDatabase(
      path,
      version: 3,
      onCreate: (Database db, int version) async {
        await db.execute('CREATE TABLE Account (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, credit TEXT, debit TEXT, balance TEXT)');
        await db.execute('CREATE TABLE MyTransaction (id INTEGER PRIMARY KEY,date TEXT , AcId INTEGER, detail TEXT, credit INTEGER, debit INTEGER)');
      },
    );

    data.selectData();

    final tables = await SecondPage.database!.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'Account']);
    (tables.isNotEmpty) ? print('Table exists!') : print('Table does not exist!');

    final table = await SecondPage.database!.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'MyTransaction']);
    (table.isNotEmpty) ? print('Table exists!') : print('Table does not exist!');
  }

  @override
  void initState() {
    super.initState();
    dataTable();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    TextStyle textStyle = TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black.withBlue(40));
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Container(
            height: height * 0.12,
            width: width,
            color: Colors.black.withBlue(40),
            alignment: Alignment.center,
            child: SizedBox(height: height * 0.06, width: height * 0.06, child: const Icon(Icons.book, color: Colors.white, size: 70)),
          ),
          Expanded(
            child: Container(
              height: height * 0.70,
              width: width,
              color: Colors.blue.shade100,
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5.0),
                          child: Text("Account Manager", style: TextStyle(fontSize: 23, color: Colors.black.withBlue(100), fontWeight: FontWeight.w600)),
                        ),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Container(
                                    width: double.infinity,
                                    height: 50,
                                    color: Colors.cyan,
                                    alignment: Alignment.center,
                                    child: const Text("Forgot Password?"),
                                  ),
                                  content: SizedBox(
                                    height: 300,
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "➽ Give following  Security questions answer for reset password.",
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        Text("➽ ${box.get("Question1")}"),
                                        TextField(controller: _answer1, decoration: const InputDecoration(hintText: "Answer")),
                                        const SizedBox(height: 10),
                                        Text("➽ ${box.get("Question2")}"),
                                        TextField(controller: _answer2, decoration: const InputDecoration(hintText: "Answer")),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            GFButton(
                                              onPressed: () {
                                                Get.back();
                                              },
                                              text: "cancel",
                                              textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 15),
                                              type: GFButtonType.outline,
                                              shape: GFButtonShape.pills,
                                              color: Colors.cyan,
                                            ),
                                            GFButton(
                                              onPressed: () {
                                                if (_answer1.text.isEmpty || _answer2.text.isEmpty) {
                                                  Fluttertoast.showToast(
                                                    msg: "Enter Answer",
                                                    toastLength: Toast.LENGTH_SHORT,
                                                    gravity: ToastGravity.SNACKBAR,
                                                    timeInSecForIosWeb: 1,
                                                    backgroundColor: Colors.cyan,
                                                    textColor: Colors.black,
                                                    fontSize: 16.0,
                                                  );
                                                } else {
                                                  if (_answer1.text == box.get("answer1") && _answer2.text == box.get("answer2")) {
                                                    Get.back();
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: Container(
                                                            width: double.infinity,
                                                            height: 50,
                                                            color: Colors.cyan,
                                                            alignment: Alignment.center,
                                                            child: const Text("Set new Password"),
                                                          ),
                                                          content: SizedBox(
                                                            height: 120,
                                                            width: double.infinity,
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                TextField(
                                                                  controller: _newpass,
                                                                  keyboardType: TextInputType.phone,
                                                                  decoration: const InputDecoration(hintText: "New Password"),
                                                                ),
                                                                const SizedBox(height: 10),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                  children: [
                                                                    GFButton(
                                                                      onPressed: () {
                                                                        Get.back();
                                                                      },
                                                                      text: "cancel",
                                                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 15),
                                                                      type: GFButtonType.outline,
                                                                      shape: GFButtonShape.pills,
                                                                      color: Colors.cyan,
                                                                    ),
                                                                    GFButton(
                                                                      onPressed: () {
                                                                        if (_newpass.text.isEmpty) {
                                                                          ScaffoldMessenger.of(
                                                                            context,
                                                                          ).showSnackBar(const SnackBar(content: Text("Enter Password")));
                                                                        } else if (_newpass.text.length <= 3) {
                                                                          ScaffoldMessenger.of(
                                                                            context,
                                                                          ).showSnackBar(const SnackBar(content: Text("Enter Valid Password")));
                                                                        } else {
                                                                          box.put('password', _newpass.text);
                                                                          ScaffoldMessenger.of(
                                                                            context,
                                                                          ).showSnackBar(const SnackBar(content: Text("Sucessfuly Reset Password")));
                                                                          Get.back();
                                                                        }
                                                                      },
                                                                      text: "Set",
                                                                      textStyle: const TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Colors.white,
                                                                        fontSize: 15,
                                                                      ),
                                                                      shape: GFButtonShape.pills,
                                                                      color: Colors.cyan,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    Fluttertoast.showToast(
                                                      msg: "Incorrect Answer",
                                                      toastLength: Toast.LENGTH_SHORT,
                                                      gravity: ToastGravity.SNACKBAR,
                                                      timeInSecForIosWeb: 1,
                                                      backgroundColor: Colors.cyan,
                                                      textColor: Colors.black,
                                                      fontSize: 16.0,
                                                    );
                                                  }
                                                }
                                              },
                                              text: "Verify",
                                              textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                              shape: GFButtonShape.pills,
                                              color: Colors.cyan,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Text("Forget Password", style: TextStyle(fontSize: 15, color: Colors.black.withBlue(40), fontWeight: FontWeight.w300)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DigitHolder(width: width, index: 0, selectedIndex: selectedindex, code: code),

                          DigitHolder(width: width, index: 1, selectedIndex: selectedindex, code: code),

                          DigitHolder(width: width, index: 2, selectedIndex: selectedindex, code: code),

                          DigitHolder(width: width, index: 3, selectedIndex: selectedindex, code: code),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: 10), Expanded(flex: 1, child: NumberPad())]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberPad extends StatelessWidget {
  final controller = Get.find<MyController>();

  final List<String> buttons = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'back', '0', 'done'];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: buttons.length,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 1.5),
      itemBuilder: (context, index) {
        final value = buttons[index];

        if (value == 'back') {
          return _buildSpecialButton(icon: Icons.backspace_outlined, color: Colors.red.shade400, onTap: controller.backspace);
        } else if (value == 'done') {
          return _buildSpecialButton(
            icon: Icons.check,
            color: Colors.green.shade400,
            onTap: () {
              if (controller.code.value == controller.get_pass().value) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
              } else {
                Fluttertoast.showToast(msg: "Wrong Password", backgroundColor: Colors.red, textColor: Colors.white, gravity: ToastGravity.CENTER);
              }
            },
          );
        } else {
          return _buildDigitButton(value);
        }
      },
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => controller.addDigit(int.parse(digit)),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, offset: Offset(1, 6), blurRadius: 10),
            BoxShadow(color: Colors.grey.shade300, offset: Offset(-1, -2), blurRadius: 15),
          ],
        ),
        child: Text(digit, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black.withBlue(40))),
      ),
    );
  }

  Widget _buildSpecialButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: Colors.black.withBlue(40), size: 30),
      ),
    );
  }
}

class DigitHolder extends StatelessWidget {
  final int selectedIndex;
  final int index;
  final String code;

  MyController data = Get.put(MyController());

  DigitHolder({required this.selectedIndex, super.key, required this.width, required this.index, required this.code});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: width * 0.17,
      width: width * 0.17,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: data.index == data.selectedindex ? Colors.cyan : Colors.transparent, offset: const Offset(0, 0), spreadRadius: 1.5, blurRadius: 2),
        ],
      ),
      child: Obx(
        () =>
            data.code.value.length > index
                ? Container(width: 15, height: 15, decoration: BoxDecoration(color: Colors.black.withBlue(40), shape: BoxShape.circle))
                : Container(),
      ),
    );
  }
}

/*Container(
        height: double.infinity, width: double.infinity,
        color: Colors.black,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30,),
                  const CircleAvatar(radius: 40,backgroundColor: Colors.brown,child: Icon(Icons.book,size: 50,color: Colors.white,),),
                  const SizedBox(height: 10,),
                  const Text("Account Manager",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Colors.white,)),
                  Container(margin: EdgeInsets.symmetric(vertical: 40,horizontal: 15),
                    height: 450,width: double.infinity,padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: Color.fromRGBO(35, 36, 38, 1),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(offset: Offset(0, 6),color: Colors.grey.shade800,blurRadius: 15,spreadRadius: 3),
                          BoxShadow(offset: Offset(6, 0),color: Colors.grey.shade800,blurRadius: 15,spreadRadius: 3),
                        ]
                    ),
                    child: Column(
                      children: [
                        Container(alignment: Alignment.center,
                          height: 50,width: double.infinity,color: Colors.white,
                          child: Text("Settings",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                        ),
                         TextField(
                           controller: _pass,keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Set Password",//labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Password must be 4 character long",style: TextStyle(color: Colors.grey.shade500),),
                        ),
                        Wrap(
                          children: [
                            Icon(Icons.arrow_circle_right,color: Colors.grey.shade500,),
                            Text("Set Security question for retrieve your password when you forget",
                              style: TextStyle(color: Colors.grey.shade500,fontSize: 15,))
                          ],
                        ),
                        TextField(
                          controller: _que1,keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Answer",labelStyle: TextStyle(color: Colors.white),),
                        ),

                        TextField(
                          controller: _que2,keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Answer",labelStyle: TextStyle(color: Colors.white),),
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(style: ElevatedButton.styleFrom(fixedSize: Size(80, 30), backgroundColor:Colors.grey),
                                onPressed: () {

                            }, child: Text("Exit")),
                            ElevatedButton(style: ElevatedButton.styleFrom(fixedSize: Size(80, 30), backgroundColor:Colors.grey),
                                onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return SecondPage();
                              },));
                                }, child: Text("Set")),
                          ],
                        )
                      ],
                    ),
                  ),
                  ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Dashbord(),)), child: Text("Dashbord"))
                ],
              ),
            )
      )*/
