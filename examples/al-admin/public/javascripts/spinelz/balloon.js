// Copyright (c) 2006 spinelz.org (http://script.spinelz.org/)
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
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

var Balloon = Class.create()
Balloon.classNames = {
  tooltip:         'balloon_tooltip',
  top:             'balloon_top',
  topLeft:         'balloon_top_left',
  topMiddle:       'balloon_top_middle',
  topRight:        'balloon_top_right',
  middle:          'balloon_middle',
  middleLeft:      'balloon_middle_left',
  middleRight:     'balloon_middle_right',
  middleLeftRowT:  'balloon_middle_left_row',
  middleLeftRowB:  'balloon_middle_left_row',
  middleRightRowT: 'balloon_middle_right_row',
  middleRightRowB: 'balloon_middle_right_row',
  leftArrow:       'balloon_left_arrow',
  rightArrow:      'balloon_right_arrow',
  leftUpArrow:     'balloon_left_up_arrow',
  leftDownArrow:   'balloon_left_down_arrow',
  rightUpArrow:    'balloon_right_up_arrow',
  rightDownArrow:  'balloon_right_down_arrow',
  body:            'balloon_body',
  bottom:          'balloon_bottom',
  bottomLeft:      'balloon_bottom_left',
  bottomMiddle:    'balloon_bottom_middle',
  bottomRight:     'balloon_bottom_right'
}
Balloon.allBalloons = [];
Balloon.closeAll = function(){
  Balloon.allBalloons.each(function(b){
    b.close();
  });
}
Balloon.eventSetting = false;
Balloon.prototype = {
  initialize : function (target, message){
    this.target = $(target);

    this.options = Object.extend({
      cssPrefix: 'custom_',
      trigger:   this.target,
      tipId:     this.target.id + '_balloon',
      events:    ['click'],
      width:     300,
      height:    200
    }, arguments[2] || {});
    
    var customCss = CssUtil.appendPrefix(this.options.cssPrefix, Balloon.classNames);
    this.classNames = new CssUtil([Balloon.classNames, customCss]);

    this.tipNode = this._buildTipNode(message);
    Element.hide(this.tipNode);
    this._setMessage(message);
    document.body.appendChild(this.tipNode);
    this._setEvent();
    Balloon.allBalloons.push(this)
    this._setSize();
  },

  _setEvent: function() {
    var self = this;
    this.options.events.each(function(e) {
      Event.observe(self.options.trigger, e, self.open.bindAsEventListener(self));
    });

    Event.observe(this.tipNode, 'click', this.close.bind(this), true)    

    if (!Balloon.eventSetting) {
      Event.observe(document, 'click', Balloon.closeAll, true);
      Balloon.eventSetting = true;
    }
  },

  _buildTipNode : function() {
    var tipNode = Builder.node('div', {id: this.options.tipId});
    this.classNames.addClassNames(tipNode, 'tooltip');
    tipNode.appendChild(this._buildTop());
    tipNode.appendChild(this._buildMiddle());
    tipNode.appendChild(this._buildBottom());
    return tipNode;
  },

  _setMessage: function(message) {
    var type = message.constructor;
    if (type == String) {
      this.body.innerHTML = message;
    } else if (type == Object) {
      this.body.appendChild(message);
    }
  },

  _buildTop: function() {
    return this._buildMulti('top', ['topLeft', 'topMiddle', 'topRight'], true);
  },

  _buildBottom: function() {
    return this._buildMulti('bottom', ['bottomLeft', 'bottomMiddle', 'bottomRight'], true);
  },

  _buildMiddle: function() {
    this.middle = Builder.node('div');
    this.classNames.addClassNames(this.middle, 'middle');
    this.middle.appendChild(
      this._buildMulti('middleLeft', ['middleLeftRowT', 'leftArrow', 'middleLeftRowB'], true));
    this.middle.appendChild(this._buildMulti('body', [], true));
    this.middle.appendChild(
      this._buildMulti('middleRight', ['middleRightRowT', 'rightArrow', 'middleRightRowB'], true));
    return this.middle;
  },

  _buildMulti: function(main, subs, hold) {
    var topNode = Builder.node('div');
    this.classNames.addClassNames(topNode, main);
    if (hold) this[main] = topNode;
    var self = this;
    var node = null;
    subs.each(function(s) {
      node = Builder.node('div');
      self.classNames.addClassNames(node, s);
      topNode.appendChild(node);
      if (hold) self[s] = node;
    });
    return topNode;
  },

  _setPosition: function() {
    var scrollPosition = Position.realOffset(this.tipNode);
    var screenWidth = document.documentElement.clientWidth;
    var screenHeight = document.documentElement.clientHeight;
    
    var positionList = Position.cumulativeOffset(this.target);
    var dimension = Element.getDimensions(this.target);
    var tipNodeLeft = Math.round(positionList[0] + dimension.width);
    var tipDimension = Element.getDimensions(this.tipNode);
    var tipNodeTop = Math.round(positionList[1] - tipDimension.height / 2);

    var addLR = 'left';
    var remLR = 'right';

    if((tmpY = tipNodeTop - scrollPosition[1]) < 0) {
      tipNodeTop -= tmpY;
    }
    if( (tipNodeLeft+tipDimension.width) > (screenWidth+scrollPosition[0]) ) {
      tipNodeLeft = Math.round(positionList[0] - tipDimension.width);
      addLR = 'right';
      remLR = 'left';
    }
    
    var y = positionList[1] - tipNodeTop;
    this._setArrow(addLR, y);
    this._unsetArrow(remLR);

    Element.setStyle(this.tipNode, {
      top: tipNodeTop + 'px',
      left: tipNodeLeft + 'px',
      zIndex: ZindexManager.getIndex()
    });
  },

  _setArrow: function(lr, y) {
    var headerH = (this.options.height - this.middleH) / 2;
    var topH, bottomH, h, ud;
    var minH = 10; // for ie
    if (lr == 'left') {
      h = this.middleH - this.leftArrowH;
    } else {
      h = this.middleH - this.rightArrowH;
    }
    if (headerH > y) {
      topH = minH;
      bottomH = h - topH;
      ud = 'up';
    } else if ((this.middleH + headerH) < y) {
      bottomH = minH;
      topH = h - bottomH;
      ud = 'down';
    } else {
      topH = y - headerH;
      topH = (topH < minH) ? minH : topH;
      bottomH = h - topH;
      ud = 'up';
    }
    if (lr == 'left') {
      if (ud == 'up') {
        this.classNames.refreshClassNames(this.leftArrow, 'leftUpArrow');
        Element.setStyle(this.leftArrow, {height: this.leftArrowH + 'px'});
        Element.setStyle(this.middleLeftRowT, {height: topH + 'px'});
        Element.setStyle(this.middleLeftRowB, {height: bottomH + 'px'});
      } else {
        this.classNames.refreshClassNames(this.leftArrow, 'leftDownArrow');
        Element.setStyle(this.leftArrow, {height: this.leftArrowH + 'px'});
        Element.setStyle(this.middleLeftRowT, {height: topH + 'px'});
        Element.setStyle(this.middleLeftRowB, {height: bottomH + 'px'});
      }
    } else {
      if (ud == 'up') {
        this.classNames.refreshClassNames(this.rightArrow, 'rightUpArrow');
        Element.setStyle(this.rightArrow, {height: this.rightArrowH + 'px'});
        Element.setStyle(this.middleRightRowT, {height: topH + 'px'});
        Element.setStyle(this.middleRightRowB, {height: bottomH + 'px'});
      } else {
        this.classNames.refreshClassNames(this.rightArrow, 'rightDownArrow');
        Element.setStyle(this.rightArrow, {height: this.rightArrowH + 'px'});
        Element.setStyle(this.middleRightRowT, {height: topH + 'px'});
        Element.setStyle(this.middleRightRowB, {height: bottomH + 'px'});
      }
    }
  },

  _unsetArrow: function(direction) {
    if (direction == 'left') {
      var h = (this.middleH - this.leftArrowH) / 2;
      this.classNames.refreshClassNames(this.leftArrow, 'middleLeftRowB');
      Element.setStyle(this.leftArrow, {height: this.leftArrowH + 'px'});
      Element.setStyle(this.middleLeftRowT, {height: h + 'px'});
      Element.setStyle(this.middleLeftRowB, {height: h + 'px'});
    } else {
      var h = (this.middleH - this.rightArrowH) / 2;
      this.classNames.refreshClassNames(this.rightArrow, 'middleRightRowB');
      Element.setStyle(this.rightArrow, {height: this.rightArrowH + 'px'});
      Element.setStyle(this.middleRightRowT, {height: h + 'px'});
      Element.setStyle(this.middleRightRowB, {height: h + 'px'});
    }
  },

  _setSize: function() {
    var width = this.options.width;
    var height = this.options.height;
    Element.setStyle(this.tipNode, {
      width: width + 'px',
      height: height + 'px'
    });

    var topH = parseInt(Element.getStyle(this.top, 'height'));
    var bottomH = parseInt(Element.getStyle(this.bottom, 'height'));
    var middleH = this.options.height - topH - bottomH;

    var style = {height: middleH + 'px'};
    Element.setStyle(this.middle, style);
    Element.setStyle(this.middleLeft, style);
    Element.setStyle(this.middleRight, style);
    Element.setStyle(this.body, style);

    this.leftArrowH = parseInt(Element.getStyle(this.leftArrow, 'height'));
    this.rightArrowH = parseInt(Element.getStyle(this.rightArrow, 'height'));
    this.middleH = middleH;
  },

  open : function() {
    if (!Element.visible(this.tipNode)) {
      this._setPosition();
      Effect.Appear(this.tipNode);
    }
  },

  close : function(){
    if (Element.visible(this.tipNode)) {
      this._setPosition();
      Effect.Fade(this.tipNode);
    }
  }
}
