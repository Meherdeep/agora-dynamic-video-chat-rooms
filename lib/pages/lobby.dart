import 'package:agora_dynamic_channels/pages/callpage.dart';
import 'package:agora_dynamic_channels/utils/appId.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LobbyPage extends StatefulWidget {
  final String username;

  const LobbyPage({Key key, this.username}) : super(key: key);

  static const routeName = '/lobby';

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool _isChannelCreated = true;
  final _channelFieldController = TextEditingController();
  String myChannel = '';

  final Map<String, List<String>> _seniorMember = {};
  final Map<String, int> _channelList = {};

  bool muted = false;
  bool _isLogin = false;
  bool _isInChannel = false;

  int count = 1;

  int x = 0;

  AgoraRtmClient _client;
  AgoraRtmChannel _channel;
  AgoraRtmChannel _subchannel;

  @override
  void dispose() {
    _channel.leave();
    _client.logout();
    _client.destroy();
    _seniorMember.clear();
    _channelList.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _createClient();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Select a channel'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isChannelCreated
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Join an existing channel or create your own. Call will start when there are at least 2 users in your channel',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Container(),
                  _isChannelCreated
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          width: MediaQuery.of(context).size.width,
                          child: ListView.builder(
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_channelList.keys.toList()[index] +
                                    '    -    ' +
                                    _channelList.values
                                        .toList()[index]
                                        .toString() +
                                    '/ 4'),
                                onTap: () {
                                  if (_channelList.values.toList()[index] <=
                                      4) {
                                    joinCall(_channelList.keys.toList()[index],
                                        _channelList.values.toList()[index]);
                                  } else {
                                    print('Channel is full');
                                  }
                                },
                              );
                            },
                            itemCount: _channelList.length,
                          ),
                        )
                      : Center(child: Text('Please create a channel first')),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          alignment: Alignment.bottomCenter,
                          child: TextFormField(
                            controller: _channelFieldController,
                            decoration: InputDecoration(
                              hintText: 'Channel Name',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.blue,
                        child: RawMaterialButton(
                          child: Text(
                            'Create',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            _createChannels(_channelFieldController.text);
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createChannels(String channelName) async {
    setState(() {
      _channelList.putIfAbsent(channelName, () => 1);
      _seniorMember.putIfAbsent(channelName, () => [widget.username]);
      myChannel = channelName;
    });
    await _channel
        .sendMessage(AgoraRtmMessage.fromText('$channelName' + ':' + '1'));
    _channelFieldController.clear();
    _subchannel = await _client.createChannel(channelName);
    await _subchannel.join();

    print('List of channels : $_channelList');
  }

  void _createClient() async {
    _client = await AgoraRtmClient.createInstance(appID);
    _client.onConnectionStateChanged = (int state, int reason) {
      if (state == 5) {
        _client.logout();
        print('Logout.');
        setState(() {
          _isLogin = false;
        });
      }
    };

    String userId = widget.username;
    await _client.login(null, userId);
    print('Login success: ' + userId);
    setState(() {
      _isLogin = true;
    });

    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print('Client message received : ${message.text}');

      var data = message.text.split(':');
      // if (_channelList.keys.contains(data[0])) {
      //   setState(() {
      //     _channelList.update(data[0], (v) => int.parse(data[1]));
      //   });
      // } else {
      //   setState(() {
      //     _channelList.putIfAbsent(data[0], () => int.parse(data[1]));
      //   });
      // }
      setState(() {
        _channelList.putIfAbsent(data[0], () => int.parse(data[1]));
      });
    };

    _channel = await _createChannel("lobby");
    await _channel.join();
    print('RTM Join channel success.');
    setState(() {
      _isInChannel = true;
    });

    // await _channel.sendMessage(AgoraRtmMessage.fromText('$localUid:join'));
    _client.onConnectionStateChanged = (int state, int reason) {
      print('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state == 5) {
        _client.logout();
        print('Logout.');
        setState(() {
          _isLogin = false;
        });
      }
    };
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) async {
      print(
          "Member joined: " + member.userId + ', channel: ' + member.channelId);
      print('All the members in the channel :  ');
      channel.getMembers().then((value) => print(value));

      _seniorMember.values.forEach(
        (element) async {
          if (element.first == widget.username) {
            // retrieve the number of users in a channel from the _channelList
            for (int i = 0; i < _channelList.length; i++) {
              if (_channelList.keys.toList()[i] == myChannel) {
                setState(() {
                  x = _channelList.values.toList()[i];
                });
              }
            }

            String data = myChannel + ':' + x.toString();
            await _client.sendMessageToPeer(
                member.userId, AgoraRtmMessage.fromText(data));
          }
        },
      );

      // for (int i = 0; i < _channelList.length; i++) {
      //   await _client.sendMessageToPeer(
      //       member.userId,
      //       AgoraRtmMessage.fromText(_channelList.keys.toList()[i] +
      //           ':' +
      //           _channelList.values.toList()[i].toString()));
      // }
    };

    channel.onMemberLeft = (AgoraRtmMember member) async {
      print("Member left: " + member.userId + ', channel: ' + member.channelId);
      await leaveCall(member.channelId, member.userId);
    };
    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) async {
      print(message.text);
      var data = message.text.split(':');
      if (_channelList.keys.contains(data[0])) {
        setState(() {
          _channelList.update(data[0], (v) => int.parse(data[1]));
        });
        if (int.parse(data[1]) >= 2 && int.parse(data[1]) < 5) {
          await _handleCameraAndMic(Permission.camera);
          await _handleCameraAndMic(Permission.microphone);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallPage(channelName: data[0]),
            ),
          );
        }
      } else {
        setState(() {
          _channelList.putIfAbsent(data[0], () => int.parse(data[1]));
        });
      }
    };
    return channel;
  }

  Future<void> joinCall(
      String channelName, int numberOfPeopleInThisChannel) async {
    _subchannel = await _client.createChannel(channelName);
    await _subchannel.join();

    print('I am in this channel ${_subchannel.channelId}');

    setState(() {
      numberOfPeopleInThisChannel = numberOfPeopleInThisChannel + 1;
    });

    print(
        'Number of the people in the created channel : $numberOfPeopleInThisChannel');

    _subchannel.getMembers().then(
          (value) => value.forEach(
            (element) {
              setState(() {
                _seniorMember.update(
                    channelName, (value) => value + [element.toString()]);
              });
            },
          ),
        );

    setState(() {
      _channelList.update(channelName, (value) => numberOfPeopleInThisChannel);
    });

    _channel.sendMessage(AgoraRtmMessage.fromText(
        '$channelName' + ':' + '$numberOfPeopleInThisChannel'));

    if (numberOfPeopleInThisChannel >= 2 && numberOfPeopleInThisChannel < 5) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await _subchannel.leave();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(channelName: channelName),
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  Future<void> leaveCall(String channelName, String leftUser) {
    setState(() {
      _channelList.update(channelName, (value) => value - 1);
    });

    _seniorMember.values.forEach((element) {
      if (element.first == leftUser) {
        setState(() {
          _seniorMember.values.forEach((element) {
            element.remove(leftUser);
          });
        });
      }
    });
  }

  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to logout'),
            actions: <Widget>[
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text("NO"),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await _channel.leave();
                  Navigator.of(context).pop(true);
                },
                child: Text("YES"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
