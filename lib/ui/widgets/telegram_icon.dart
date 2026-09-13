import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Настоящий знак Telegram (векторный, красится в любой цвет).
class TelegramIcon extends StatelessWidget {
  const TelegramIcon({this.size = 16, this.color, super.key});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return SvgPicture.asset(
      'assets/telegram.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}