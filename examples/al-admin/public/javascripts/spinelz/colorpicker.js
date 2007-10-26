// Copyright (c) 2007 spinelz.org (http://script.spinelz.org/)
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

var ColorPicker = Class.create();
ColorPicker.className = {
}

ColorPicker.prototype = {
  initialize: function(element) {
    this.element = $(element);
    Element.setStyle(this.element, {position: 'absolute'});
    this.hide();
    this.element.innerHTML = this.build();
    this.setEvent();
    this.doclistener = this.hide.bindAsEventListener(this);
    if (!UserAgent.isIE()) {
      Element.setStyle(this.element, {
        width: 15 * 18 + 'px',
        height: 15 * 12 + 'px'
      });
    }
    Element.setStyle(this.element, {border: '3px solid gray'});
    this.setting = $H({});
    this.triggerId = null;
  },

  set: function(setting) {
    var trigger = $(setting.trigger);
    this.setting[trigger.id] = setting;
    Event.observe(trigger, 'click', this.show.bindAsEventListener(this, trigger.id));
  },

  build: function() {
    var colors = [0, 0, 0];
    var rgb = null;
    var id = null;
    var idBase = this.element.id;
    var html = "<div style='cursor: pointer;'>";
    var halfCount = 51 * 3;
    this.idList = [];
    for (var i = 0; i <= 255; i += 51) {
      if (i == halfCount) html += "<div style='clear: left;'></div>";
      for (var j = 0; j <= 255; j += 51) {
        html += "<div style='float: left; width: 15px;'>";
        for (var k = 0; k <= 255; k += 51) {
          rgb = "#" + i.toColorPart() + j.toColorPart() + k.toColorPart();
          id = idBase.appendSuffix(rgb);
          this.idList.push(id);
          html += "<div id='" + id + "' style='width: 100%; height: 15px; background-color: " + rgb + "'></div>";
        }
        html += "</div>"
      }
    }
    return html + "</div>";
  },

  setEvent: function() {
    this.idList.each(function(id) {
//      Event.observe(id, 'mouseover', this.mouseOver.bind(this, id));
      Event.observe(id, 'mousedown', this.mouseDown.bind(this, id));
    }.bind(this));
  },

  mouseOver: function(id) {
    this.setColor(id.getSuffix());
  },

  mouseDown: function(id) {
    this.setValue(id.getSuffix());
    this.setColor(id.getSuffix());
  },

  setValue: function(color) {
    var valueTarget = $(this.setting[this.triggerId].value);
    if (valueTarget) {
      if (valueTarget.tagName.toLowerCase() == 'input') {
        valueTarget.value = color;
      } else {
        valueTarget.innerHTML = color;
      }
    }
  },

  setColor: function(color) {
    var colorTarget = $(this.setting[this.triggerId].color);
    if (colorTarget) {
      Element.setStyle(colorTarget, {backgroundColor: color});
    }
  },

  show: function(event, triggerId) {
    this.triggerId = triggerId;
    Element.setStyle(this.element, { 
      zIndex: ZindexManager.getIndex(),
      left:   Event.pointerX(event) + 'px',
      top:    Event.pointerY(event) + 'px'
    });
    this.element.show();
    Event.observe(document, "click", this.doclistener);
    if (event) {
      Event.stop(event);
    }
  },

  hide: function() {
    this.triggerId = null;
    Event.stopObserving(document, "click", this.doclistener);
    this.element.hide();
  }
}
