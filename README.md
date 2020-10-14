To use, extend a webcore view type, for example:
```haxe
class Example extends webcore.WebGLView {

}
```

Then when embedding on a native platform, your class will be exposed via `WebCore.createView(className)`. For example, in js:

```js
let example = WebCore.createView('Example');
// in js, webcore views are implemented with DOM elements
document.body.appendChild(example);
```

**Units**

- `points` - Abstract length units independent of the display's physical pixel density. All coordinates and dimensions in this API are given in units of `points`. In UIKit this maps the `points` unit, in Android the `density independent pixel` and in HTML it maps to the `px` unit
- `pixels` - Corresponds to individually addressable values in a texture or display

See [iOS Documentation: Points Verses Pixels](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW7)

**Input**

Generally input events follow the latest browser input event specifications, however there are small differences, for example: to prevent the platform's default handling for an event, return `true` from an event handling method
- For mouse, touch and pen input, an interface that closely follows the PointerEvent API is used
- Wheel events mirror browser [WheelEvent](https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent) where all deltas are in units of **points**, normalizing for `deltaMode`
- KeyboardEvents mirror browser [KeyboardEvent](https://w3c.github.io/uievents/#idl-keyboardevent) with an extra parameter `hasFocus` to detect if the view is focused for the event