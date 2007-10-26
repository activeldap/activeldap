// Copyright (c) 2005 spinelz.org (http://script.spinelz.org/)
// 
// This code is substantially based on code from Thomas Fakes(http://craz8.com) 
// which has the following copyright and permission notice
// 
// Copyright (c) 2005 Thomas Fakes (http://craz8.com)
// 
// This code is substantially based on code from script.aculo.us which has the 
// following copyright and permission notice
//
// Copyright (c) 2005 Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

ResizeableWindowEx = Class.create();
Object.extend(Object.extend(ResizeableWindowEx.prototype, Resizeable.prototype), {
  startResize: function(event) {
    if (Event.isLeftClick(event)) {
      
      // abort on form elements, fixes a Firefox issue
      var src = Event.element(event);
      if(src.tagName && (
        src.tagName=='INPUT' ||
        src.tagName=='SELECT' ||
        src.tagName=='BUTTON' ||
        src.tagName=='TEXTAREA')) return;

      var dir = this.directions(event);
      if (dir.length > 0) {      
        this.active = true;
        var offsets = Position.cumulativeOffset(this.element);
        this.startTop = offsets[1];
        this.startLeft = offsets[0];
        this.startWidth = parseInt(Element.getStyle(this.element, 'width'));
        this.startHeight = parseInt(Element.getStyle(this.element, 'height'));
        this.startX = event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
        this.startY = event.clientY + document.body.scrollTop + document.documentElement.scrollTop;
        
        this.currentDirection = dir;
        Event.stop(event);
      }

      if (this.options.restriction) {
        var parent = this.element.parentNode;
        var dimensions = Element.getDimensions(parent);
        this.parentOffset = Position.cumulativeOffset(parent);
        this.parentWidth = this.parentOffset[0] + dimensions.width;
        this.parentHeight = this.parentOffset[1] + dimensions.height;
      }
    }
  },

  draw: function(event) {
    var pointer = [Event.pointerX(event), Event.pointerY(event)];
    if (this.options.restriction &&
      (
        (this.parentWidth <= pointer[0])
        || (this.parentHeight <= pointer[1])
        || (this.parentOffset[0] >= pointer[0])
        || (this.parentOffset[1] >= pointer[1])
      )) return;

    var style = this.element.style;
    var newHeight = style.height;
    var newWidth = style.width;
    var newTop = style.top;
    var newLeft = style.left;

    if (this.currentDirection.indexOf('n') != -1) {
      var pointerMoved = this.startY - pointer[1];
      var margin = Element.getStyle(this.element, 'margin-top') || "0";
      newHeight = this.startHeight + pointerMoved;
      newTop = (this.startTop - pointerMoved - parseInt(margin)) + "px";
    }
    
    if (this.currentDirection.indexOf('w') != -1) {
      var pointerMoved = this.startX - pointer[0];
      var margin = Element.getStyle(this.element, 'margin-left') || "0";
      newWidth = this.startWidth + pointerMoved;
      newLeft = this.startLeft - pointerMoved - parseInt(margin);
      if (this.options.restriction) newLeft -= this.parentOffset[0];
      newLeft += 'px';
    }
    
    if (this.currentDirection.indexOf('s') != -1) {
      newHeight = this.startHeight + pointer[1] - this.startY;
    }
    
    if (this.currentDirection.indexOf('e') != -1) {
      newWidth = this.startWidth + pointer[0] - this.startX;
    }
    
    var newStyle = {
      height: newHeight,
      width: newWidth,
      top: newTop,
      left: newLeft
    }
    if (this.options.draw) {
      this.options.draw(newStyle, this.element);
    }
      
    if (newHeight && newHeight > this.options.minHeight) {
      style.top = newStyle.top;
      style.height = newStyle.height + "px";
    }
    if (newWidth && newWidth > this.options.minWidth) {
      style.left = newStyle.left;
      style.width = newStyle.width + "px";
    }
    if(style.visibility=="hidden") style.visibility = ""; // fix gecko rendering
  }
});
