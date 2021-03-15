import 'package:flutter/material.dart';

class VerticalSpacer extends StatelessWidget {
  final double percentage;

  const VerticalSpacer({Key key, this.percentage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * percentage,
    );
  }
}