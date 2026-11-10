import 'package:flutter/material.dart';

class MyTextLabel extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final TextAlign? textAlign;

  const MyTextLabel({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.color = Colors.black87,
    this.padding,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: textAlign,
      ),
    );
  }
}
