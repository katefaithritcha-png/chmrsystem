import 'package:flutter/material.dart';

/// Responsive design helper for handling different screen sizes
class ResponsiveHelper {
  static const double mobileSmallBreakpoint = 320; // Small phones
  static const double mobileLargeBreakpoint = 600; // Large phones
  static const double tabletBreakpoint = 900; // Tablets
  static const double desktopBreakpoint = 1200; // Desktop

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileLargeBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileLargeBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileLargeBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(12);
      case DeviceType.tablet:
        return const EdgeInsets.all(16);
      case DeviceType.desktop:
        return const EdgeInsets.all(24);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    final deviceType = getDeviceType(context);
    tabletSize ??= mobileSize + 2;
    desktopSize ??= mobileSize + 4;

    switch (deviceType) {
      case DeviceType.mobile:
        return mobileSize;
      case DeviceType.tablet:
        return tabletSize;
      case DeviceType.desktop:
        return desktopSize;
    }
  }

  /// Get responsive width for content
  static double getContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileLargeBreakpoint) {
      return width;
    } else if (width < tabletBreakpoint) {
      return width * 0.9;
    } else {
      return 1000; // Max width for desktop
    }
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 8;
      case DeviceType.tablet:
        return 12;
      case DeviceType.desktop:
        return 16;
    }
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 8;
      case DeviceType.tablet:
        return 12;
      case DeviceType.desktop:
        return 16;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 24;
      case DeviceType.tablet:
        return 32;
      case DeviceType.desktop:
        return 40;
    }
  }

  /// Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 44;
      case DeviceType.tablet:
        return 48;
      case DeviceType.desktop:
        return 56;
    }
  }

  /// Get responsive card height
  static double getResponsiveCardHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 120;
      case DeviceType.tablet:
        return 140;
      case DeviceType.desktop:
        return 160;
    }
  }

  /// Get responsive list item height
  static double getResponsiveListItemHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 60;
      case DeviceType.tablet:
        return 70;
      case DeviceType.desktop:
        return 80;
    }
  }

  /// Get responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = getResponsivePadding(context);

    return width - (padding.left + padding.right);
  }

  /// Check if should show sidebar
  static bool shouldShowSidebar(BuildContext context) {
    return isDesktop(context);
  }

  /// Check if should show drawer
  static bool shouldShowDrawer(BuildContext context) {
    return isMobile(context);
  }

  /// Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return 56;
      case DeviceType.tablet:
        return 64;
      case DeviceType.desktop:
        return 72;
    }
  }
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop }

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Responsive layout widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}
