import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void registerCameraIllustration() {
  ui_web.platformViewRegistry.registerViewFactory(
    'css-camera',
    (int viewId) {
      final wrapper = web.document.createElement('div') as web.HTMLDivElement;
      wrapper.style.width = '400px';
      wrapper.style.height = '265px';
      wrapper.style.position = 'relative';
      wrapper.style.overflow = 'visible';
      wrapper.style.transform = 'scale(0.3333)';
      wrapper.style.transformOrigin = '0 0';
      wrapper.insertAdjacentHTML(
        'afterbegin',
        '''
        <div class="cam-container">
          <div class="camera-top">
            <div class="zoom"></div>
            <div class="mode-changer"></div>
            <div class="sides"></div>
            <div class="range-finder"></div>
            <div class="focus"></div>
            <div class="red"></div>
            <div class="view-finder"></div>
            <div class="flash"><div class="light"></div></div>
          </div>
          <div class="camera-mid">
            <div class="sensor"></div>
            <div class="lens"></div>
          </div>
          <div class="camera-bottom"></div>
        </div>
        '''.toJS,
      );
      return wrapper;
    },
  );
}
