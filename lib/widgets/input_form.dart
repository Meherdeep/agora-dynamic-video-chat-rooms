import 'package:agora_dynamic_channels/pages/lobby.dart';
import 'package:agora_dynamic_channels/widgets/verticalspacer.dart';
import 'package:flutter/material.dart';

class InputForm extends StatelessWidget {
  static final _loginformKey = GlobalKey<FormState>();
  TextEditingController _username = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _loginformKey,
      child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Image.network(
                    'https://www.agora.io/en/wp-content/uploads/2019/06/agoralightblue-1.png'),
              ),
              VerticalSpacer(
                percentage: 0.15,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        width: 3,
                        color: Colors.red,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.blue, width: 2)),
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Username',
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter your Email ID';
                    } else {
                      return null;
                    }
                  },
                  controller: _username,
                ),
              ),
              VerticalSpacer(
                percentage: 0.3,
              ),
              Container(
                alignment: Alignment.bottomCenter,
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.16,
                child: MaterialButton(
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LobbyPage(
                          username: _username.text,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Sign in My Account',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
