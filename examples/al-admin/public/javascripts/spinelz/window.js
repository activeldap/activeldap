// Copyright (c) 2006 spinelz.org (http://script.spinelz.org/)
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

var Window = Class.create();
Window.className = {
  window:       'window',
  header:       'window_header',
  headerLeft:   'window_headerLeft',
  headerMiddle: 'window_headerMiddle',
  headerRight:  'window_headerRight',
  buttonHolder: 'window_buttonHolder',
  closeButton:  'window_closeButton',
  maxButton:    'window_maxButton',
  minButton:    'window_minButton',
  body:         'window_body',
  bodyLeft:     'window_bodyLeft',
  bodyMiddle:   'window_bodyMiddle',
  bodyRight:    'window_bodyRight',
  bottom:       'window_bottom',
  bottomLeft:   'window_bottomLeft',
  bottomMiddle: 'window_bottomMiddle',
  bottomRight:  'window_bottomRight'
}

Window.prototype = {
  
  initialize: function(element) {
    var options = Object.extend({
      className:          Window.className.window,
      width:              300,
      height:             300,
      minWidth:           200,
      minHeight:          40,
      drag:               true,
      resize:             true,
      resizeX:            true,
      resizeY:            true,
      modal:              false,
      closeButton:        true,
      maxButton:          true,
      minButton:          true,
      cssPrefix:          'custom_',
      restriction:        false,
      endDrag:            Prototype.emptyFunction,
      endResize:          Prototype.emptyFunction,
      addButton:          null,
      preMaximize:        function() {return true},
      preMinimize:        function() {return true},
      preRevertMaximize:  function() {return true},
      preRevertMinimize:  function() {return true},
      preClose:           function() {return true},
      endMaximize:        Prototype.emptyFunction,
      endMinimize:        Prototype.emptyFunction,
      endRevertMaximize:  Prototype.emptyFunction,
      endRevertMinimize:  Prototype.emptyFunction,
      endClose:           Prototype.emptyFunction,
      dragOptions:        {},
      appendToBody:       false,
      defaultButtonWidth: 16,
      displayNone:        true,
      build:              true
    }, arguments[1] || {});
    
    this.classNames = CssUtil.getInstance(options.cssPrefix, Window.className).allJoinClassNames();
    
    this.element = $(element);
    this.options = options;
    Element.setStyle(this.element, {visibility: 'hidden'});
    if (UserAgent.isSafari()) Element.setStyle(this.element, {position: 'absolute'});
    if (this.options.displayNone) Element.hide(this.element);
    this.element.className = this.options.className;
    
    this.elementId = this.element.id;
    this.dragHandleId = this.element.id + '_dragHandle';
    this.buttonHolderId = this.element.id + '_buttonHolder';
    this.bodyMiddleId = this.element.id + '_bodyMiddle';
    
    this.maxZindex = -1;
    this.minFlag = false;
    this.maxFlag = false;
    this.currentPos = [0,0];
    this.currentSize = [0,0];

    this.ids = {};
    this.addButtons = [];
    if (this.options.build && !this.element.buildedWindow) {
      this.buildWindow();
    } else {
      this.initHeight();
      if (this.options.drag) this.createDraggble();
      if (this.options.resize) this.enableResizing();
    }
    this.cover = new IECover(this.element, {padding: 10});
    
    Element.makePositioned(element);
    Element.hide(this.element);
    Element.setStyle(this.element, {visibility: 'visible'});

    if (this.options.appendToBody) Element.appendToBody.callAfterLoading(this, this.element);
    if (this.options.build && !this.element.buildedWindow) $(this.bodyMiddleId).down(0).appendChild(this.content);
    this.element.buildedWindow = true;
  },

  buildWindow: function() {
    Element.cleanWhitespace(this.element);
    
    with (this.element.style) {
      width = this.options.width + 'px';
      height= this.options.height + 'px';
    }

    var title = this.element.childNodes[0];
    var content = this.element.childNodes[1];
    this.element.innerHTML = this.buildHeader(title) + this.buildBody(content) + this.buildBottom();
    this.initHeight();
    this.setEvent();
  },

  initHeight: function() {
    this.header = $(this.getId('header'));
    this.windowBody = $(this.getId('bodyContainer'));
    this.bottom = $(this.getId('bottom'));
    var newStyle = {height: this.options.height};
    this.setBodyHeight(newStyle);
  },

  setEvent: function() {
    if (this.options.drag) this.createDraggble();
    if (this.options.resize) this.enableResizing();

    var width = 0;
    var defaultWidth = this.options.defaultButtonWidth;

    if (this.ids.closeButton) {
      width += defaultWidth;
      Event.observe(this.ids.closeButton, 'click', this.close.bindAsEventListener(this));
    }
    if (this.ids.maxButton) {
      width += defaultWidth;
      Event.observe(this.ids.maxButton, 'click', this.maximize.bindAsEventListener(this));
    }
    if (this.ids.minButton) {
      width += defaultWidth;
      Event.observe(this.ids.minButton, 'click', this.minimize.bindAsEventListener(this));
    }

    this.addButtons.each(function(button) {
      width += button.width || defaultWidth;
      Event.observe(button.id, 'click', button.onclick.bindAsEventListener(this));
    }.bind(this));

    Element.setStyle(this.buttonHolderId, {width: width + 'px'});
  },

  buildHeader: function(title) {
    var handleStyle = (this.options.drag) ? "" : " style='cursor: default;'";
    return "<div id='" + this.getId('header') + "' class='" + this.classNames['header'] + "'>" + 
      "<div class='" + this.classNames['headerLeft'] + "'></div>" + 
      "<div id='" + this.dragHandleId + "'class='" + this.classNames['headerMiddle'] + "'" + handleStyle + ">" +
        Element.outerHTML(title) +
      "</div>" + 
      this.buildButtons() +
      "<div class='" + this.classNames['headerRight'] + "'></div>" + 
    "</div>";
  },

  buildButtons: function() {
    var buttons = "";

    if (this.options.closeButton) {
      this.ids.closeButton = this.getId('closeButton');
      buttons += "<div id='" + this.ids.closeButton + "' class='" + this.classNames['closeButton'] + "'></div>";
    }
    if (this.options.maxButton) {
      this.ids.maxButton = this.getId('maxButton');
      buttons += "<div id='" + this.ids.maxButton + "' class='" + this.classNames['maxButton'] + "'></div>";
    }
    if (this.options.minButton) {
      this.ids.minButton = this.getId('minButton');
      buttons += "<div id='" + this.ids.minButton + "' class='" + this.classNames['minButton'] + "'></div>";
    }

    if (this.options.addButton) {
      var addButton = this.options.addButton;
      if (addButton.constructor == Function) {
        buttons = addButton(buttons);
      } else if (addButton.constructor == Array) {
        var self = this;
        addButton.each(function(b) {
          this.addButtons.push(b);
          var added = "<div id='" + b.id + "' class='" + b.className + "'></div>";
          buttons = (b.first) ? buttons + added : added + buttons;
        }.bind(this));
      }
    }

    return "<div id='" + this.buttonHolderId + "'class='" + this.classNames['buttonHolder'] + "'>" + buttons + "</div>";
  },
  
  buildBody: function(content) {
    var holder = document.createDocumentFragment();
    holder.appendChild(content);
    this.content = content;

    return "<div id='" + this.getId('bodyContainer') + "' class='" + this.classNames['body'] + "'>" + 
      "<div class='" + this.classNames['bodyLeft'] + "'></div>" + 
      "<div id='" + this.bodyMiddleId + "' class='" + this.classNames['bodyMiddle'] + "'>" +
        "<div style='width: 100%; height: 100%; overflow: auto; position: relative;'></div>" +
      "</div>" + 
      "<div class='" + this.classNames['bodyRight'] + "'></div>" + 
    "</div>";
  },
  
  buildBottom: function() {
    return "<div id='" + this.getId('bottom') + "' class='" + this.classNames['bottom'] + "'>" + 
      "<div class='" + this.classNames['bottomLeft'] + "'></div>" + 
      "<div class='" + this.classNames['bottomMiddle'] + "'></div>" + 
      "<div class='" + this.classNames['bottomRight'] + "'></div>" + 
    "</div>";
  },

  getId: function(suffix) {
    return this.element.id.appendSuffix(suffix);
  },

  createDraggble: function() {
    var options = Object.extend({
      handle:      this.dragHandleId,
      starteffect: Prototype.emptyFunction,
      endeffect:   Prototype.emptyFunction,
      endDrag:     this.options.endDrag,
      scroll:      window
    }, this.options.dragOptions);

    if (this.options.restriction) {
      if (this.options.restriction.constructor == String) {
        this._setRestriction(options, $(this.options.restriction));
      } else {
        this._setRestriction(options, this.element.parentNode);
      }
    } else {
      var p = Position.cumulativeOffset(Position.offsetParent(this.element));
      options.snap = function(x, y) {
        return [
          ((x + p[0]) >= 0) ? x : 0 - p[0], 
          ((y + p[1]) >= 0) ? y : 0 - p[1]
        ];
      }
    }
    new DraggableWindowEx(this.element, options);
  },

  setWindowZindex : function(zIndex) {
    zIndex = this.getZindex(zIndex);
    this.element.style.zIndex = zIndex;
  },
  
  getZindex: function(zIndex) {
    return ZindexManager.getIndex(zIndex);
  },
  
  open: function(zIndex) {
    this.opening = true;
    Element.show(this.element);
    if (this.options.modal && !UserAgent.isMac()) {
      Modal.mask(this.element, {zIndex: zIndex});
    } else {
      this.setWindowZindex(zIndex);
    }
    this.cover.resetSize();
    this.opening = false;
    if (this.shouldClose) {
      this.close();
      this.shouldClose = false;
    }
  },
      
  close: function() {
    if (this.opening) this.shouldClose = true;
    if (!this.options.preClose(this)) return;
    this.element.style.zIndex = -1;
    this.maxZindex = -1;
    try {
      Element.hide(this.element);
    } catch(e) {}
    if (this.options.modal) {
      Modal.unmask();
    }
    this.options.endClose(this);
    if (this.opening) this.shouldClose = true;
  },

  minimize: function(event) {
    if (this.minFlag) {
      if (!this.options.preRevertMinimize(this)) return;
      Element.toggle(this.windowBody);
      if (this.maxFlag) {
        this.minFlag = false;
        this.setMax();
      } else {         
        var newStyle = {height:this.currentSize[1]}
        this.setBodyHeight(newStyle);
        this.element.style.width = this.currentSize[0];
        this.element.style.height = this.currentSize[1]; 
        this.element.style.left = this.currentPos[0];
        this.element.style.top = this.currentPos[1];
        this.maxFlag = false;
        this.minFlag = false;
        this.options.endRevertMinimize(this);
      }
    } else {
      if (!this.options.preMinimize(this)) return;
      Element.toggle(this.windowBody);
      if (!this.maxFlag) {
        this.currentPos = [Element.getStyle(this.element, 'left'), Element.getStyle(this.element, 'top')];
        this.currentSize = [Element.getStyle(this.element, 'width'), Element.getStyle(this.element, 'height')];
      }
      this.setMin();
      this.minFlag = true;
      this.options.endMinimize(this);
    }
    this.cover.resetSize();
  },
    
  maximize: function(event) {
    if (this.maxFlag) {
      if (this.minFlag) {
        Element.toggle(this.windowBody);
        this.minFlag = false;
        this.setMax();
      } else {
        if (!this.options.preRevertMaximize(this)) return;
        var newStyle = {height:parseInt(this.currentSize[1])}
        this.setBodyHeight(newStyle);
        this.element.style.width = this.currentSize[0];
        this.element.style.height = this.currentSize[1]; 
        this.element.style.left = this.currentPos[0];
        this.element.style.top = this.currentPos[1];
        this.maxFlag = false;
        this.minFlag = false;        
        document.body.style.overflow = '';
        this.element.style.position = this.position;
        for(var i = 0; i < this.nodeArray.length; i++) {
          this.parent.appendChild(this.nodeArray[i]);
        }
        this.options.endRevertMaximize(this);
      }
    
    } else {
      if (!this.options.preMaximize(this)) return;
      if (!this.minFlag) {
        this.currentPos = [Element.getStyle(this.element, 'left'), Element.getStyle(this.element, 'top')];
        this.currentSize = [Element.getStyle(this.element, 'width'), Element.getStyle(this.element, 'height')];        
      } else {
        Element.toggle(this.windowBody);
        this.minFlag = false;
      }
      this.parent = this.element.parentNode;
      this.nodeArray = new Array();
      this.setNodePosition();
      this.nodeIndex = 0;
      this.position = Element.getStyle(this.element, 'position');
      document.body.style.overflow = 'hidden';
      document.body.appendChild(this.element);
      this.element.style.position = 'absolute';
      this.setMax();
      this.maxFlag = true;
      this.options.endMaximize(this);
    }
    this.cover.resetSize();
  },
    
  setNodePosition : function() {
    var children = this.parent.childNodes;
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      if (child.id == this.elementId) {
        this.nodeIndex = i;
      }
      this.nodeArray.push(child);
    }
  },
    
  setMin : function() {
    var minHeight = this.header.offsetHeight + this.bottom.offsetHeight;
    var minWidth = this.options.minWidth;
    this.element.style.height = minHeight + 'px';
    this.element.style.width = minWidth + 'px';
  },
        
  setMax : function(zIndex) {
    var maxW = Element.getWindowWidth();
    var maxH = Element.getWindowHeight();
    var newStatus = {height:maxH}
    with(this.element.style) {
      width = maxW + 'px';
      height = maxH + 'px';
      left = '0px';
      top = '0px';
    }
    this.setBodyHeight(newStatus);
    this.setWindowZindex(zIndex);  
  },
  
  _getParentWidth: function(parent) {
    if (parent && parent.style) {
      var width = parent.style.width;
      var index = 0;
      if (width) {
        if ((index = width.indexOf('px', 0)) > 0) {
      return parseInt(width);
        } else if ((index = width.indexOf('%', 0)) > 0) {
          var pw = this._getParentWidth(parent.parentNode);
      
          var par = parseInt(width);
          return pw * par / 100;
        } else if (!width.isNaN) {
          return parseInt(width);
        }      
      } else if (parent == document.body){
        return Element.getWindowWidth();
      }
    }
  },

  setHeight: function(height) {
    height = {height: height};
    Element.setStyle(this.element, height);
    this.setBodyHeight(height);
  },
  
  setBodyHeight: function(newStyle) {
    var height = parseInt(newStyle.height, 10);
    if (height > this.options.minHeight) {
      var newHeight = null;
      if (this.options.displayNone) {
        newHeight = (height - parseInt(Element.getStyle(this.header, 'height'), 10) -
          parseInt(Element.getStyle(this.bottom, 'height'), 10)) + 'px';
      } else {
        newHeight = (height - this.header.offsetHeight - this.bottom.offsetHeight) + 'px';
      }
      var childNodes = Element.getTagNodes(this.windowBody);
      childNodes[0].style.height = newHeight;
      childNodes[1].style.height = newHeight;
      childNodes[2].style.height = newHeight;
      this.windowBody.style.height = newHeight;
    }
    if (this.cover) this.cover.resetSize();
  },

  center: function() {
    var w = parseInt(Element.getStyle(this.element, 'width'));
    var h = parseInt(Element.getStyle(this.element, 'height'));

    var offsetParent = Position.offsetParent(this.element);
    var pOffset = Position.cumulativeOffset(offsetParent);

    var left = (Element.getWindowWidth() - w) / 2;
    var top = (Element.getWindowHeight() - h) / 2;

    var realOffset = Position.realOffset(offsetParent);
    var scrollTop = realOffset.last();
    var scrollLeft = realOffset.first();

    top += scrollTop - pOffset[1];
    left += scrollLeft - pOffset[0];
    top = ((top + pOffset[1]) >= 0) ? top : 0 - pOffset[1];
    left = ((left + pOffset[0]) >= 0) ? left : 0 - pOffset[0];
    Element.setStyle(this.element, {left: left + 'px', top: top + 'px'});
  },

  moveTo: function(position) {
    var style = {};
    if (position.left) {
      style.left = (position.left.constructor != String) ? (position.left + 'px') : position.left;
    }
    if (position.top) {
      style.top = (position.top.constructor != String) ? (position.top + 'px') : position.top;
    }
    Element.setStyle(this.element, style);
  },

  moveBy: function(position) {
    var style = {};
    if (position.left) {
      style.left = (parseInt(Element.getStyle(this.element, 'left'), 10) + position.left) + 'px';
    }
    if (position.top) {
      style.top = (parseInt(Element.getStyle(this.element, 'top'), 10) + position.top) + 'px';
    }
    Element.setStyle(this.element, style);
  },

  enableResizing: function() {
    var resTop = this.options.resizeY ? 6 : 0;
    var resBottom = this.options.resizeY ? 6 : 0;
    var resLeft = this.options.resizeX ? 6 : 0;
    var resRight = this.options.resizeX ? 6 : 0;
    this.resizeable = new ResizeableWindowEx(this.element, { 
      top:         resTop,
      bottom:      resBottom,
      left:        resLeft,
      right:       resRight,
      minWidth:    this.options.minWidth,
      minHeight:   this.options.minHeight,
      draw:        this.setBodyHeight.bind(this),
      resize:      this.options.endResize,
      restriction: this.options.restriction,
      zindex:      2000
    });
  },

  disableResizing: function() {
    this.resizeable.destroy();
  },

  _setRestriction: function(options, restrictionNode) {
    options.snap = function(x, y) {
      function constrain(n, lower, upper) {
        if (n > upper) return upper; 
        else if (n < lower) return lower;
        else return n;
      }

      var eDimensions = Element.getDimensions(this.element);
      var pDimensions = Element.getDimensions(restrictionNode);

      if (Element.getStyle(restrictionNode, 'position') == 'static') {
        var offset = Position.positionedOffset(restrictionNode);
        var parentLeft = offset[0];
        var parentTop = offset[1];
        return [
          constrain(x, parentLeft, parentLeft + pDimensions.width - eDimensions.width),
          constrain(y, parentTop, parentTop + pDimensions.height - eDimensions.height)
        ];
      } else {
        var offsetTop = 0
        var offsetLeft = 0
        if (restrictionNode != this.element.parentNode) {
          var restOffset = Position.cumulativeOffset(restrictionNode);
          var parentOffset = Position.cumulativeOffset(Position.offsetParent(this.element));
          offsetLeft = restOffset[0] - parentOffset[0];
          offsetTop = restOffset[1] - parentOffset[1];
        }
        return [
          constrain(x, offsetLeft, (pDimensions.width - eDimensions.width) + offsetLeft),
          constrain(y, offsetTop, (pDimensions.height - eDimensions.height) + offsetTop)
        ];
      }
    }.bind(this)
  }
}


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

var DraggableWindowEx = Class.create();
Object.extend(DraggableWindowEx.prototype, Draggable.prototype);
Object.extend(DraggableWindowEx.prototype, {
  initDrag: function(event) {
    if(Event.isLeftClick(event)) {    
      // abort on form elements, fixes a Firefox issue
      var src = Event.element(event);
      if(src.tagName && (
        src.tagName=='INPUT' ||
        src.tagName=='SELECT' ||
        src.tagName=='OPTION' ||
        src.tagName=='BUTTON' ||
        src.tagName=='TEXTAREA')) return;
        
      if(this.element._revert) {
        this.element._revert.cancel();
        this.element._revert = null;
      }
      
      var pointer = [Event.pointerX(event), Event.pointerY(event)];
      var pos     = Position.cumulativeOffset(this.element);
      this.offset = [0,1].map( function(i) { return (pointer[i] - pos[i]) });

      var zIndex = ZindexManager.getIndex();
      this.originalZ = zIndex;
      this.options.zindex = zIndex;
      Element.setStyle(this.element, {zIndex: zIndex});
      
      Draggables.activate(this);
      Event.stop(event);
    }
  },

  endDrag: function(event) {
    if(!this.dragging) return;
    this.stopScrolling();
    this.finishDrag(event, true);

    this.options.endDrag();
    Event.stop(event);
  }
});

