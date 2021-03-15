import 'package:agora_dynamic_channels/utils/appId.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';

class LobbyPage extends StatefulWidget {
  final String username;

  const LobbyPage({Key key, this.username}) : super(key: key);

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool _isChannelCreated = false;
  final _channelFieldController = TextEditingController();
  static final listOfChannels = <String>[];

  final Map<int, String> _allUsers = {};

  bool _isLogin = false;
  bool _isInChannel = false;

  AgoraRtmClient _client;
  AgoraRtmChannel _channel;

  @override
  void dispose() {
    _channel.leave();
    _client.logout();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Select a channel'),
        ),
        body: SafeArea(
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isChannelCreated
                    ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Join an existing channel or create your own',
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
                              title: Text(listOfChannels[index]),
                              onTap: null,
                            );
                          },
                          itemCount: listOfChannels.length,
                        ),
                      )
                    : Center(child: Text('Please create a channel first')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      alignment: Alignment.bottomCenter,
                      child: TextFormField(
                        controller: _channelFieldController,
                        decoration: InputDecoration(
                            hintText: 'Channel Name',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.circular(20))),
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
        ));
  }

  Future<void> _createChannels(String channelName) async {
    _channelFieldController.clear();

    await _createClient(channelName);

    if (channelName != null && listOfChannels.length == 0) {
      setState(() {
        _isChannelCreated = true;
        listOfChannels.add(channelName);
      });
    } else {
      setState(() {
        listOfChannels.add(channelName);
      });
    }

    print(listOfChannels);
  }

  Future<void> _createClient(String channelName) async {
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
    _channel = await _createChannel(channelName);
    await _channel.join();
    print('RTM Join channel success.');
    setState(() {
      _isInChannel = true;
    });
    // await _channel.sendMessage(AgoraRtmMessage.fromText('$localUid:join'));
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Peer msg: " + peerId + ", msg: " + message.text);

      var userData = message.text.split(':');

      if (userData[1] == 'leave') {
        print('In here');
        setState(() {
          _allUsers.remove(int.parse(userData[0]));
        });
      } else {
        setState(() {
          _allUsers.putIfAbsent(int.parse(userData[0]), () => peerId);
        });
      }
    };
    _channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      print(
          'Outside channel message received : ${message.text} from ${member.userId}');

      var userData = message.text.split(':');

      if (userData[1] == 'leave') {
        setState(() {
          _allUsers.remove(int.parse(userData[0]));
        });
      } else {
        // print('Broadcasters list : $_users');
        print('All users lists: ${_allUsers.values}');
        setState(() {
          _allUsers.putIfAbsent(int.parse(userData[0]), () => member.userId);
        });
      }
    };

    // for (var i = 0; i < _users.length; i++) {
    //   if (_allUsers.containsKey(_users[i])) {
    //     setState(() {
    //       _broadcaster.add(_allUsers[_users[i]]);
    //     });
    //   } else {
    //     setState(() {
    //       _audience.add('${_allUsers.values}');
    //     });
    //   }
    // }
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) async {
      print('Member joined : ${member.userId}');
      // setState(() {

      // });
      // await _client.sendMessageToPeer(
      //     member.userId, AgoraRtmMessage.fromText('$localUid:join'));
    };
    channel.onMemberLeft = (AgoraRtmMember member) async {
      var reversedMap = _allUsers.map((k, v) => MapEntry(v, k));
      print('Member left : ${member.userId}:leave');
      print('Member left : ${reversedMap[member.userId]}:leave');

      setState(() {
        _allUsers.remove(reversedMap[member.userId]);
      });
      await channel.sendMessage(
          AgoraRtmMessage.fromText('${reversedMap[member.userId]}:leave'));
    };
    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      print('Channel message received : ${message.text} from ${member.userId}');

      var userData = message.text.split(':');

      if (userData[1] == 'leave') {
        _allUsers.remove(int.parse(userData[0]));
      } else {
        _allUsers.putIfAbsent(int.parse(userData[0]), () => member.userId);
      }
    };
    return channel;
  }
}
