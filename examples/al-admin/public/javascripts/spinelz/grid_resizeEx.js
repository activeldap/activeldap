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

ResizeableGridEx = Class.create();
Object.extend(Object.extend(ResizeableGridEx.prototype, Resizeable.prototype), {

  draw: function(event) {
    
    var pointer = [Event.pointerX(event), Event.pointerY(event)];
    var style = this.element.style;
    var newHeight = 0;
    var newWidth = 0;
    var newTop = 0;
    var newLeft = 0;
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
      newLeft = (this.startLeft - pointerMoved - parseInt(margin))  + "px";
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
  },

  directions: function(event) {
    var pointer = [Event.pointerX(event) + Grid.scrollLeft, Event.pointerY(event) + Grid.scrollTop];
    //var pointer = [Event.pointerX(event), Event.pointerY(event)];    
    var offsets = Position.cumulativeOffset(this.element);
  var cursor = '';
  if (this.between(pointer[1] - offsets[1], 0, this.options.top)) cursor += 'n';
  if (this.between((offsets[1] + this.element.offsetHeight) - pointer[1], 0, this.options.bottom)) cursor += 's';
  if (this.between(pointer[0] - offsets[0], 0, this.options.left)) cursor += 'w';
  if (this.between((offsets[0] + this.element.offsetWidth) - pointer[0], 0, this.options.right)) cursor += 'e';
  
  return cursor;
  }
});
