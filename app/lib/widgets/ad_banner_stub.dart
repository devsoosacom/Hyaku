import 'package:flutter/widgets.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key, this.height = 100});
  final double height;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
