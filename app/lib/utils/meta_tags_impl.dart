import 'dart:js_interop';

@JS('updateMeta')
external void _updateMetaJs(JSString title, JSString desc, JSString url, JSString imageUrl);

@JS('resetMeta')
external void _resetMetaJs();

@JS('updateArticleLd')
external void _updateArticleLdJs(JSString title, JSString desc, JSString url, JSString datePublished, JSString author);

void updatePageMeta(String title, String description, String url, {String? imageUrl}) {
  try {
    _updateMetaJs(title.toJS, description.toJS, url.toJS, (imageUrl ?? '').toJS);
  } catch (_) {}
}

void resetPageMeta() {
  try {
    _resetMetaJs();
  } catch (_) {}
}

void updateArticleLd(String title, String description, String url, String datePublished, String author) {
  try {
    _updateArticleLdJs(title.toJS, description.toJS, url.toJS, datePublished.toJS, author.toJS);
  } catch (_) {}
}
