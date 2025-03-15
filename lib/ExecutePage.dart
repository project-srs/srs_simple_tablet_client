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
    createListItem(endpoint, name){
      return ListTile(
        title: Text(name),
        onTap: () async {
          final response = await http.post(
              Uri.http('${widget.hostname}:8010', endpoint),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, String>{
                'name': name,
                'comment': "${name} by app"
              }));
          print("response: " + response.body);
          Navigator.of(context).pop();
        }
      );
    }

    createOptionItem(name, endpoint, post_content){
      return SimpleDialogOption(
        child: Text(name),
        onPressed: () async {
          final response = await http.post(
            Uri.http('${widget.hostname}:8010', endpoint),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: post_content
          );
          print("response: " + response.body);
          Navigator.pop(context, post_content);
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
          // mode
          var jsonData = jsonDecode(snapshot.data);
          modeText = jsonData['mode_name'];
          final Map<String, Color> modeColorMap = {
            'red' : Colors.red,
            'green' : Colors.green,
            'blue' : Colors.blue,
            'yellow' : Colors.yellow,
            'gray' : Colors.white54
          };
          if (modeColorMap.containsKey(jsonData['mode_color'])) {
            modeColor = modeColorMap[jsonData['mode_color']]!;
          }
          // notes
          for (var jsonItem in jsonData['notes']){
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
          // board
          final Map<String, String> iconImageMap = {
            'error' : "images/326633_error_icon.png",
            'move' : "images/9057017_play_button_o_icon.png",
            'pause' : "images/3671827_outline_pause_icon.png",
            'turn' : "images/6428070_arrow_recycle_refresh_reload_return_icon.png",
            'manual' : "images/9025635_game_controller_icon.png",
            'wait_input' : "images/9165539_tap_touch_icon.png",
          };
          if (iconImageMap.containsKey(jsonData['board_icon'])) {
            boardIconFileName = iconImageMap[jsonData['board_icon']]!;
          }
          boardText = jsonData["board_message"];
          // mode_list
          modeWidgets.add(const DrawerHeader(
            child: Text("Operation Mode")
          ));
          for (var jsonItem in jsonData['modes']){
            modeWidgets.add(createListItem(jsonItem["endpoint"], jsonItem["name"]));
          }
          // action
          if (0 < jsonData["actions"].length) {
            List<Widget> optionList = [];
            for (var item in jsonData["actions"]) {
              optionList.add(createOptionItem(item["name"], item["endpoint"], item["post_content"]));
            }

            actionButtonWidget = FloatingActionButton(
              onPressed: () async {
                // Add your onPressed code here!
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