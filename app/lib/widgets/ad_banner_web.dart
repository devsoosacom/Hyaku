import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@JS('adsbygooglePush')
external void _adsbygooglePush();

// TODO: 以下の2つの値をAdSenseアカウントの実際の値に変更してください
// https://adsense.google.com → 広告 → 広告ユニット → ディスプレイ広告
const _adClient = 'ca-pub-3891518799622736';
const _adSlot = '0000000000';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key, this.height = 100});
  final double height;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  static int _counter = 0;
  late final String _viewType;
  bool _adReady = false;

  @override
  void initState() {
    super.initState();
    _counter++;
    _viewType = 'adsense-$_counter';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container =
          web.document.createElement('div') as web.HTMLDivElement;
      container.style.width = '100%';
      container.style.height = '${widget.height}px';
      container.style.overflow = 'hidden';

      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
      ins.style.display = 'block';
      ins.setAttribute('data-ad-client', _adClient);
      ins.setAttribute('data-ad-slot', _adSlot);
      ins.setAttribute('data-ad-format', 'auto');
      ins.setAttribute('data-full-width-responsive', 'true');

      container.append(ins);

      web.window.setTimeout((() {
        _adsbygooglePush();
      }).toJS, 300.toJS);

      return container;
    });

    setState(() => _adReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_adReady) return SizedBox(height: widget.height);
    return Container(
      height: widget.height,
      color: const Color(0xFF0F0F0F),
      child: Stack(
        children: [
          HtmlElementView(viewType: _viewType),
          Positioned(
            top: 4,
            left: 8,
            child: Text(
              'スポンサー',
              style: GoogleFonts.notoSerifJp(
                fontSize: 9,
                color: const Color(0xFF444444),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
