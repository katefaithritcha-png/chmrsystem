import 'package:flutter/material.dart';
import 'responsive_helper.dart';

/// Responsive text widget that scales based on device
class ResponsiveText extends StatelessWidget {
  final String text;
  final double mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final TextStyle? style;

  const ResponsiveText(
    this.text, {
    required this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobileSize: mobileSize,
      tabletSize: tabletSize,
      desktopSize: desktopSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive heading 1
class ResponsiveHeading1 extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign textAlign;

  const ResponsiveHeading1(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      mobileSize: 24,
      tabletSize: 28,
      desktopSize: 32,
      fontWeight: FontWeight.bold,
      color: color,
      textAlign: textAlign,
    );
  }
}

/// Responsive heading 2
class ResponsiveHeading2 extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign textAlign;

  const ResponsiveHeading2(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      mobileSize: 20,
      tabletSize: 24,
      desktopSize: 28,
      fontWeight: FontWeight.bold,
      color: color,
      textAlign: textAlign,
    );
  }
}

/// Responsive heading 3
class ResponsiveHeading3 extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign textAlign;

  const ResponsiveHeading3(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      mobileSize: 16,
      tabletSize: 20,
      desktopSize: 24,
      fontWeight: FontWeight.w600,
      color: color,
      textAlign: textAlign,
    );
  }
}

/// Responsive body text
class ResponsiveBody extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const ResponsiveBody(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      mobileSize: 14,
      tabletSize: 15,
      desktopSize: 16,
      fontWeight: FontWeight.normal,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive caption text
class ResponsiveCaption extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign textAlign;

  const ResponsiveCaption(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      mobileSize: 12,
      tabletSize: 13,
      desktopSize: 14,
      fontWeight: FontWeight.normal,
      color: color,
      textAlign: textAlign,
    );
  }
}

/// Responsive label text
class ResponsiveLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign textAlign;

  const ResponsiveLabel(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      mobileSize: 13,
      tabletSize: 14,
      desktopSize: 15,
      fontWeight: FontWeight.w500,
      color: color,
      textAlign: textAlign,
    );
  }
}
