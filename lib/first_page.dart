import 'package:account_manager/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'second_page.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _que1 = TextEditingController();
  final TextEditingController _que2 = TextEditingController();

  String dropvalue = 'Security Question';
  Box box = Hive.box("Account");

  List<String> Question1 = [
    "What was the first mobile that you purchased?",
    "What was the name of your best friend at childhood?",
    "What was the name of your first pet?",
    "What is your favourite children's book?",
    "What was the first film you saw in the cinema?",
    "What was the name of your favourite teacher in school?",
  ];

  List<String> Question2 = [
    "What is the name of your favourite sports team?",
    "Who was your favourite singer or band?",
    " What is your first job?",
    "What was the first dish you learned to cook?",
    "What was the model of your first motorised vehicle?",
    "What was your childhood nickname?",
  ];

  String? _selected1, _selected2;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 50),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset("assets/images/logo.png", height: 80)),
              const SizedBox(height: 10),
              Text("Account Manager", style: Theme.of(context).poppinsBold.copyWith(fontSize: 24)),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(color: MyColors.primaryColor, borderRadius: BorderRadius.circular(10)),
                        child: Text("Set Password", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
                      ),
                      Container(
                        height: 50,
                        margin: const EdgeInsets.fromLTRB(5, 20, 5, 5),
                        child: TextField(
                          inputFormatters: [LengthLimitingTextInputFormatter(4), FilteringTextInputFormatter.digitsOnly],
                          controller: _pass,
                          obscureText: true,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Set Password",
                            labelStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Password must be 4 character long", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                      ),
                      Text(
                        "➽ Set Security question for retrieve your password when you forget",
                        style: Theme.of(context).poppinsRegular.copyWith(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: DropdownButton(
                          isExpanded: true,
                          underline: Container(),
                          hint: Text('Security Question 1', style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                          value: _selected1,
                          onChanged: (newValue) {
                            setState(() {
                              _selected1 = newValue;
                            });
                          },
                          items: Question1.map((location) {
                            return DropdownMenuItem(
                              value: location,
                              child: Text(location, style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                            );
                          }).toList(),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(5),
                        height: 50,
                        child: TextField(
                          controller: _que1,
                          decoration: InputDecoration(
                            labelText: "Answer",
                            labelStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: DropdownButton(
                          isExpanded: true,
                          underline: Container(),
                          hint: Text('Security Question 2', style: Theme.of(context).poppinsMedium.copyWith(fontSize: 14)),
                          value: _selected2,
                          onChanged: (newValue) {
                            setState(() {
                              _selected2 = newValue;
                            });
                          },
                          items: Question2.map((location) {
                            return DropdownMenuItem(
                              value: location,
                              child: Text(location, style: Theme.of(context).poppinsRegular.copyWith(fontSize: 14)),
                            );
                          }).toList(),
                        ),
                      ),
                      Container(
                        height: 50,
                        margin: const EdgeInsets.all(5),
                        child: TextField(
                          controller: _que2,
                          decoration: InputDecoration(
                            labelText: "Answer",
                            labelStyle: Theme.of(context).poppinsMedium.copyWith(fontSize: 14, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(fixedSize: const Size(200, 50), backgroundColor: MyColors.primaryColor),
                    onPressed: () {
                      if (_pass.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter Password")));
                      } else if (_pass.text.length <= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter Valid Password")));
                      } else if (_selected1 == null || _selected2 == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Both Security Question")));
                      } else if (_que1.text.isEmpty || _que2.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter Both Answer")));
                      } else {
                        String Question1, Question2, answer1, answer2;
                        Question1 = _selected1!;
                        Question2 = _selected2!;
                        answer1 = _que1.text;
                        answer2 = _que2.text;

                        box.put('password', _pass.text);
                        box.put("Question1", Question1);
                        box.put("Question2", Question2);
                        box.put("answer1", answer1);
                        box.put("answer2", answer2);

                        print(box.get('password'));

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return SecondPage();
                            },
                          ),
                        );
                      }
                    },
                    child: Text("Save", style: Theme.of(context).poppinsMedium.copyWith(fontSize: 18, color: Colors.white)),
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
