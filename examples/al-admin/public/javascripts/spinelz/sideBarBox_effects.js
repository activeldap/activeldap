// Copyright (c) 2005 spinelz.org (http://script.spinelz.org/)
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

Effect.SlideRightIntoView = function(element) {
  element = $(element);
  Element.cleanWhitespace(element);

  var oldInnerRight = element.firstChild.style.right;
  var elementDimensions = Element.getDimensions(element);
  return new Effect.Scale(element, 100, 
   Object.extend({ scaleContent: false, 
    scaleY: false, 
    scaleFrom: 0,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},    
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      Element.makePositioned(effect.element.firstChild);
      if (window.opera) effect.element.firstChild.style.left = "";
      Element.makeClipping(effect.element);
      element.style.width = '0';
      Element.show(element); 
    },  
    afterUpdateInternal: function(effect) { 
      effect.element.firstChild.style.right = 
        (effect.dims[1] - effect.element.clientWidth) + 'px'; },
    afterFinishInternal: function(effect) { 
      Element.undoClipping(effect.element); 
      Element.undoPositioned(effect.element.firstChild);
      effect.element.firstChild.style.right = oldInnerRight; }
    }, arguments[1] || {})
  );
}

Effect.SlideRightOutOfView = function(element) {
  element = $(element);
  Element.cleanWhitespace(element);
  var oldInnerRight = element.firstChild.style.right;
  return new Effect.Scale(element, 0, 
   Object.extend({ scaleContent: false, 
    scaleY: false, 
    scaleMode: 'box',
    scaleFrom: 100,
    restoreAfterFinish: true,
    beforeStartInternal: function(effect) { 
      Element.makePositioned(effect.element.firstChild);
      if (window.opera) effect.element.firstChild.style.left = "";
      Element.makeClipping(effect.element);
      Element.show(element); 
    },  
    afterUpdateInternal: function(effect) { 
     effect.element.firstChild.style.right = 
       (effect.dims[1] - effect.element.clientWidth) + 'px'; },
    afterFinishInternal: function(effect) { 
        Element.hide(effect.element);
        Element.undoClipping(effect.element); 
        Element.undoPositioned(effect.element.firstChild);
        effect.element.firstChild.style.right = oldInnerRight; }
   }, arguments[1] || {})
  );
}
