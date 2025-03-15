import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SimpleDialogSample extends StatelessWidget {
  final List<Widget> optionList;

  const SimpleDialogSample({Key? key, required this.optionList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('select item'),
      children: optionList,
    );
  }
}

class ExecutePage extends StatefulWidget {
  const ExecutePage({Key? key, required this.hostname}) : super(key: key);

  final String hostname;
  final int port = 8010;

  @override
  State<ExecutePage> createState() => _ExecutePage();
}

class _ExecutePage extends State<ExecutePage> {
  final _scrollController = ScrollController();
  WebSocketChannel? statusChannel;

  @override
  void initState() {
    super.initState();
    statusChannel = WebSocketChannel.connect(Uri.parse('ws://${widget.hostname}:8010/status'));
  }

  @override
  Widget build(BuildContext context) {
    createDrawerListItem(goal_id, key, display_name){
      return ListTile(
        title: Text(display_name),
        onTap: () async {
          final response = await http.post(
              Uri.http('${widget.hostname}:8010', '/select/drawer'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, String>{
                'goal_id': goal_id,
                'key': key
              }));
          print("response: " + response.body);
          Navigator.of(context).pop();
        }
      );
    }

    createActionOptionItem(goal_id, key, display_name){
      return SimpleDialogOption(
        child: Text(display_name),
        onPressed: () async {
          final response = await http.post(
            Uri.http('${widget.hostname}:8010', '/select/action'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'goal_id': goal_id,
              'key': key
            }));
          print("response: " + response.body);
          Navigator.pop(context);
        },
      );
    }

    return StreamBuilder(
      stream: statusChannel?.stream,
      builder: (context, snapshot) {
        var modeText = "no connection";
        var modeColor = Colors.white54;
        var boardIconFileName = 'images/326633_error_icon.png';
        var boardText = "erorr";
        List<Widget> noteWidgets = [];
        Widget? actionButtonWidget = null;
        List<Widget> modeWidgets = [];

        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          var jsonData = jsonDecode(snapshot.data);

          // select.drawer
          modeWidgets.add(const DrawerHeader(
            child: Text("Operation Mode")
          ));
          for (var item in jsonData["select"]["drawer"]["options"]){
            modeWidgets.add(createDrawerListItem(item["goal_id"], item["key"], item["display_name"]));
          }

          // select.action
          if (0 < jsonData["select"]["action"]["options"].length) {
            List<Widget> optionList = [];
            for (var item in jsonData["select"]["action"]["options"]) {
              optionList.add(createActionOptionItem(item["goal_id"], item["key"], item["display_name"]));
            }

            actionButtonWidget = FloatingActionButton(
              onPressed: () async {
                final String? selectedText = await showDialog<String>(
                  context: context,
                  builder: (_) {
                    return SimpleDialogSample(optionList: optionList,);
                  }
                );
                print(selectedText);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.navigation),
            );
          }

          // display.header
          modeText = jsonData['display']['header']['name'];
          final Map<String, Color> modeColorMap = {
            'red' : Colors.red,
            'green' : Colors.green,
            'blue' : Colors.blue,
            'yellow' : Colors.yellow,
            'gray' : Colors.white54
          };
          if (modeColorMap.containsKey(jsonData['display']['header']['color'])) {
            modeColor = modeColorMap[jsonData['display']['header']['color']]!;
          }
          // display.board
          final Map<String, String> iconImageMap = {
            'error' : "images/326633_error_icon.png",
            'move' : "images/9057017_play_button_o_icon.png",
            'pause' : "images/3671827_outline_pause_icon.png",
            'turn' : "images/6428070_arrow_recycle_refresh_reload_return_icon.png",
            'manual' : "images/9025635_game_controller_icon.png",
            'wait_input' : "images/9165539_tap_touch_icon.png",
          };
          if (iconImageMap.containsKey(jsonData["display"]["board"]['icon'])) {
            boardIconFileName = iconImageMap[jsonData["display"]["board"]['icon']]!;
          }
          boardText = jsonData["display"]["board"]["message"];

          // notes
          for (var jsonItem in jsonData['note']['contents']){
            var noteColor = Colors.white38;
            final Map<String, Color> noteColorMap = {
              'info' : Colors.white,
              'warning' : Colors.yellow,
              'error' : Colors.red,
            };
            if (noteColorMap.containsKey(jsonItem['level'])) {
              noteColor = noteColorMap[jsonItem['level']]!;
            }
            noteWidgets.add(
              Text(
                jsonItem["message"],
                style: TextStyle(fontSize: 30, color:noteColor),
              )
            );
          }
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: modeColor,
            title: Text(
              modeText,
              style: TextStyle(
                fontSize: 80,
              ),
            ),
            centerTitle: true,
            toolbarHeight: 150, 
          ),
          endDrawer: Drawer(
            child: ListView(
              children: modeWidgets
            )
          ),
          floatingActionButton: actionButtonWidget,
          body: Column(
            children: <Widget>[
              Expanded(
                flex: 4, // 割合.
                child: Container(
                  color: Colors.white12,
                  child: Scrollbar(
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 12,
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      children: noteWidgets
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6, // 割合.
                child: Container(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Image.asset(boardIconFileName, color: Colors.white)
                        ),
                      ),
                      Text(boardText,
                        style: TextStyle(
                          fontSize: 80,
                          color: Colors.white
                        ),
                      ),
                    ],
                  )
                ),            
              )
            ]
          ),
        );
      }
    );
  }
}