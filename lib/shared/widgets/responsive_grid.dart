import 'package:flutter/material.dart';
import '../../core/responsive/responsive_helper.dart';

/// Responsive grid widget that adapts to screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);

    int columns;
    switch (deviceType) {
      case DeviceType.mobile:
        columns = mobileColumns ?? 1;
        break;
      case DeviceType.tablet:
        columns = tabletColumns ?? 2;
        break;
      case DeviceType.desktop:
        columns = desktopColumns ?? 3;
        break;
    }

    return Padding(
      padding: padding,
      child: GridView.count(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: _getAspectRatio(deviceType),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }

  double _getAspectRatio(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
    }
  }
}

/// Responsive list widget
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;
  final ScrollPhysics physics;

  const ResponsiveList({
    Key? key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
    this.physics = const ScrollPhysics(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final responsiveSpacing = ResponsiveHelper.getResponsiveSpacing(context);

    return ListView.separated(
      padding: padding.add(responsivePadding),
      itemCount: children.length,
      physics: physics,
      separatorBuilder: (context, index) => SizedBox(height: responsiveSpacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive row that wraps on small screens
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    if (isMobile) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// Responsive container with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contentWidth = ResponsiveHelper.getMaxContentWidth(context);
    final maxContentWidth =
        maxWidth ?? ResponsiveHelper.getContentWidth(context);
    final width =
        contentWidth < maxContentWidth ? contentWidth : maxContentWidth;

    return Center(
      child: Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

/// Responsive spacer
class ResponsiveSpacer extends StatelessWidget {
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;

  const ResponsiveSpacer({
    Key? key,
    this.mobileHeight = 16,
    this.tabletHeight = 20,
    this.desktopHeight = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveSpacing(context);
    return SizedBox(height: height);
  }
}

/// Responsive divider
class ResponsiveDivider extends StatelessWidget {
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const ResponsiveDivider({
    Key? key,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing / 2),
      child: Divider(
        thickness: thickness ?? 1,
        color: color,
        indent: indent ?? spacing,
        endIndent: endIndent ?? spacing,
      ),
    );
  }
}
