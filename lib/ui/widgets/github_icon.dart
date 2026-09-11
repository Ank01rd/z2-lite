import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Настоящий логотип GitHub (векторный, красится в любой цвет).
class GithubIcon extends StatelessWidget {
  const GithubIcon({this.size = 16, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return SvgPicture.asset(
      'assets/github.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}