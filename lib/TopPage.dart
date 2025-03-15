import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './ExecutePage.dart';

class TopPage extends StatefulWidget {
  const TopPage({super.key});

  @override
  State<TopPage> createState() => _TopPage();
}

class _TopPage extends State<TopPage> {
  var _hostname_input_controller = TextEditingController();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  
  @override
  void initState() {
    super.initState();
  
    Future(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _hostname_input_controller.text = prefs.getString('target_hostname') ?? '';
        print(prefs.getString('target_hostname'));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('srs simple tablet client'),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: <Widget>[
              Container(
                width: 150,
                child: TextField(
                  controller: _hostname_input_controller,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async{
                  var hostname = _hostname_input_controller.text;
                  final SharedPreferences prefs = await _prefs;
                  prefs.setString('target_hostname', hostname);

                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context)=>ExecutePage(hostname: hostname),)
                  );
                },
                child: Text('Execute Window'),
              ),
            ],
          ),
        ),
      ),
    );  
  }
}

