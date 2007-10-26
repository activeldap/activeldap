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

/**
 * Element class
 */
Object.extend(Element, {
  
  elementNode: 1,

  textNode: 3,

  isElementNode: function(element) {
    return element.nodeType == Element.elementNode;
  },

  isTextNode: function(element) {
    return element.nodeType == Element.textNode;
  },

  isWhitespace: function(element) {
    return (Element.isTextNode(element) && !/\S/.test(element.nodeValue));
  },

  hasTagName: function(element, tagName) {
    return (Element.isElementNode(element) && element.tagName.toLowerCase() == tagName.toLowerCase());
  },

  getTagNodes: function(element, tree) {
    return this.getElementsByNodeType(element, Element.elementNode, tree);
  },
  
  getTextNodes: function(element, tree) {
    return this.getElementsByNodeType(element, Element.textNode, tree);
  },

  getChildNodesWithoutWhitespace: function(element) {
    return $A(element.childNodes).select(function(node) {
      return Element.isElementNode(node) || !Element.isWhitespace(node);
    });
  },
  
  getElementsByNodeType: function(element, nodeType, tree) {
    element = ($(element) || document.body);
    var nodes = element.childNodes;
    var result = [];
    
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].nodeType == nodeType)
        result.push(nodes[i]);
      if (tree && Element.isElementNode(nodes[i]))
        result = result.concat(this.getElementsByNodeType(nodes[i], nodeType, tree));
    }
    return result;
  },
  
  getParentByClassName: function(className, element) {
    var parent = element.parentNode;
    if (!parent || (parent.tagName == 'BODY'))
      return null;
    else if (!parent.className) 
      return Element.getParentByClassName(className, parent);
    else if (Element.hasClassName(parent, className))
      return parent;
    else
      return Element.getParentByClassName(className, parent);
  },
  
  getParentByTagName: function(tagNames, element) {
    var parent = element.parentNode;
    if (parent.tagName == 'BODY')
      return null;
      
    var index = tagNames.join('/').toUpperCase().indexOf(parent.tagName.toUpperCase(), 0);
    if (index >= 0)
      return parent;
    else
      return Element.getParentByTagName(tagNames, parent);
  },
  
  getFirstElementByClassNames: function(element, classNames, tree) {
    if (!element || 
        !((typeof(classNames) == 'object') && (classNames.constructor == Array))) {
      return;  
    }
  
    element = (element || document.body);
    var nodes = element.childNodes;
    
    for (var i = 0; i < nodes.length; i++) {
      for (var j = 0; j < classNames.length; j++) {
        if (!Element.isElementNode(nodes[i])) {
          continue;
        } else if (Element.hasClassName(nodes[i], classNames[j])) {
          return nodes[i];
        } else if (tree) {
          var result = this.getFirstElementByClassNames(nodes[i], classNames, tree);
          if (result) return result;
        }
      }
    }
    
    return;
  },
  
  getElementsByClassNames: function(element, classNames) {
    if (!element || 
        !((typeof(classNames) == 'object') && (classNames.constructor == Array))) {
      return;  
    }
  
    var nodes = [];
    classNames.each(function(c) {
      nodes = nodes.concat(document.getElementsByClassName(c, element));
    });
    return nodes;
  },
  
  getWindowHeight: function() {
    if (window.innerHeight) {
      return window.innerHeight; // Mozilla, Opera, NN4
    } else if (UserAgent.isIE() && !UserAgent.isIE7()) {
      return Element.body().clientHeight;
    } else {
      return Element.body().offsetHeight;
    }
    return 0;
  },
  
  getWindowWidth:function() {
    if (UserAgent.isIE() && !UserAgent.isIE7()) {
      return Element.body().clientWidth;
    } else {
      return Element.body().offsetWidth;
    }
    return 0;
  },
  
  getMaxZindex: function(element) {
    element = $(element);
    if (!element) {
      element = document.body;
    }  
    if (!Element.isElementNode(element)) return 0;

    var maxZindex = 0;
    if (element.style) maxZindex = parseInt(Element.getStyle(element, "z-index"));  
    if (isNaN(maxZindex)) maxZindex = 0;

    var tmpZindex = 0;
    var elements = element.childNodes;
    for (var i = 0; i < elements.length; i++) {
      if (elements[i] && elements[i].tagName) {
        tmpZindex = Element.getMaxZindex(elements[i]);
        if (maxZindex < tmpZindex) maxZindex = tmpZindex;
      }
    }
    return maxZindex;
  },

  select: function(element, value) {
    $A($(element).options).each(function(opt) {
      opt.selected = (opt.value == value);
    });
  },

  selectAll: function(element) {
    $A($(element).options).each(function(opt) { opt.selected = true; });
  },

  removeOptions: function(element) {
    $A($(element).options).each(function(opt) {
      if (opt.selected) Element.remove(opt);
    });
  },

  getSelectedOptions: function(element) {
    return $A($(element).options).select(function(opt) { return opt.selected; });
  },

  check: function(elements, id) {
    elements.each(function(element) {
      element = $(element);
      if (element) element.checked = (element.id == id);
    });
  },

  outerHTML: function(element) {
    element = $(element);
    var html = '';
    if (Element.isTextNode(element)) {
      html = element.nodeValue;
    } else if (Element.isElementNode(element)) {
      if (element.outerHTML) {
        html = element.outerHTML;
      } else {
        var attrList = [element.tagName];
        var attributes = element.attributes;
        if (attributes) {
          $A(attributes).each(function(attr) {
            attrList.push(attr.name + '="' + attr.value.escapeHTML().replace(/"/, '&quot;') + '"');
          });
        }
        html = "<" + attrList.join(' ') + ">" + element.innerHTML + "</" + element.tagName + ">";
      }
    }
    return html;
  },

  // too late
  eventHTML: function(element) {
    return $A(element.attributes).map(function(attr) {
      if (attr.name.match(/^on(\w)+/)) {
        return attr.name + '="' + attr.value + '"';
      } else {
        return '';
      }
    }).join(' ');
  },

  attributeHTML: function(element, attribute) {
    var html = '';
    if (element[attribute]) {
      html = element[attribute].toString().replace(/\'/g, '\"');
      html = attribute + "='(" + html + ")()'";
    }
    return html;
  },
 
  replaceOptions: function(element, options) {
    element = $(element);
    element.innerHTML = '';
    var df = document.createDocumentFragment();
    options.each(function(values) {
      df.appendChild(Builder.node('option', {value: values.last()}, [values.first().unescapeHTML()]));
    });
    $(element).appendChild(df);
  },

  body: function() {
    return document.documentElement || document.body;
  },

  scrollTop: function() {
    return Element.body().scrollTop;
  },

  scrollLeft: function() {
    return Element.body().scrollLeft;
  },

  // for performance
  setStyle: function(element, style) {
    element = $(element);
    var eStyle = element.style;
    for (var name in style)
      eStyle[name.camelize()] = style[name];
    return element;
  },

  appendToBody: function(element) {
    element = $(element);
    Element.removeFromBody(element.id)
    document.body.appendChild(element);
  },
  
  removeFromBody: function(dom_id) {
    $A(document.body.childNodes).each(function(node){
      if (node.id == dom_id) node.remove();
    });
  }
});
Element.addMethods({setStyle: Element.setStyle});


/**
 * Array
 */
Object.extend(Array.prototype, {
  insert : function(index, element) {
    this.splice(index, 0 , element);
  },
  
  remove : function(index) {
    this.splice(index, 1);
  }
});


/**
 * String
 */
Object.extend(String.prototype, {
  
  getPrefix: function(delimiter) {
  
    if (!delimiter) delimiter = '_';
    return this.split(delimiter)[0];
  },
  
  getSuffix: function(delimiter) {
    
    if (!delimiter) delimiter = '_';
    return this.split(delimiter).pop();
  },

  appendPrefix: function(prefix, delimiter) {
  
    if (!delimiter) delimiter = '_';
    return this + delimiter + prefix;
  },
  
  appendSuffix: function(suffix, delimiter) {
    if (!delimiter) delimiter = '_';
    return this + delimiter + suffix;
  },

  toElement: function() {
    var tmpNode = document.createElement('div');
    tmpNode.innerHTML = this;
    return tmpNode.firstChild;
  }
});


/**
 * CssUtil
 */
var CssUtil = Class.create();

CssUtil.getInstance = function(prefix, style) {
  var newStyle = CssUtil.appendPrefix(prefix, style);
  return new CssUtil([style, newStyle]);
}

CssUtil.appendPrefix = function(prefix, suffixes) {
  var newHash = {};
  $H(suffixes).each(function(pair) {
    newHash[pair[0]] = prefix + suffixes[pair[0]];
  });
  return newHash;
}

CssUtil.getCssRules = function(sheet) {
  return sheet.rules || sheet.cssRules;
}

CssUtil.getCssRuleBySelectorText = function(selector) {
  var rule = null;
  $A(document.styleSheets).each(function(s) {
    var rules = CssUtil.getCssRules(s);
    rule =  $A(rules).detect(function(r) {
      if (!r.selectorText) return false;
      return r.selectorText.toLowerCase() == selector.toLowerCase();
    });
    if (rule) throw $break;
  });
  return rule;
}

/*
CssUtil.require = function(file, attributes, parent) {
  var links = document.getElementsByTagName('link');
  var regex = /^.*\.css/; 
  var match = file.match(regex)
  alert(file)
  regex.compile(match);

  $A(links).each(function(ln) {
    if (ln.href.match(regex)) {
    }
  });
  
//  attributes = Object.extend({
//                  href: file, 
//                  media: 'screen', 
//                  rel: 'stylesheet', 
//                  type: 'text/css'}, attributes);
//  var node = Builder.node('link', attributes);
//  if (!parent) parent = document.body;
//  parent.appendChild(node);
//  alert(file);
}
*/

CssUtil.prototype = {
  
  initialize: function(styles) {
    if (!((typeof(styles) == 'object') && (styles.constructor == Array))) {
      throw 'CssUtil#initialize: argument must be a Array object!';    
    }
    this.styles = styles;
  },

  getClasses: function(key) {
    return this.styles.collect(function(s) {
      return s[key];
    });
  },
  
  joinClassNames: function(key) {
    return this.getClasses(key).join(' ');
  },

  allJoinClassNames: function() {
    var classes = {};
    $H(this.styles.first()).each(function(pair) {
      classes[pair.key] = this.joinClassNames(pair.key);
    }.bind(this));
    return classes;
  },
  
  addClassNames: function(element, key) {
    this.styles.each(function(s) {
      Element.addClassName(element, s[key]);
    });
  },
  
  removeClassNames: function(element, key) {
    this.styles.each(function(s) {
      Element.removeClassName(element, s[key]);
    });
  },
  
  refreshClassNames: function(element, key) {
    element.className = '';
    this.addClassNames(element, key);
  },
  
  hasClassName: function(element, key) {
    return this.styles.any(function(s) {
      return Element.hasClassName(element, s[key]);
    });
  }
}


/** 
 * Hover 
 */
var Hover = Class.create();
Hover.prototype = {

  initialize: function(element) {
    this.options = Object.extend({
      defaultClass: '',
      hoverClass:   '',
      cssUtil:      '',
      list:         false,
      beforeToggle: function() { return true; }
    }, arguments[1] || {});
    
    var element = $(element);
    if (this.options.list) {
      var nodes = element.childNodes;
      for (var i = 0; i < nodes.length; i++) {
        if (Element.isElementNode(nodes[i])) {
          this.build(nodes[i]);
        }
      }
    } else {
      this.build(element);
    }
    this.element = element;
  },
  
  build: function(element) {
    this.normal = this.getNormalClass(element);
    this.hover = this.getHoverClass(this.normal);
    
    if (this.options.cssUtil) {
      this.normal = this.options.cssUtil.joinClassNames(normal);
      this.hover = this.options.cssUtil.joinClassNames(hover);    
    }
    this.setHoverEvent(element);
  },

  setHoverEvent: function(element) {
    this.mouseout = this.toggle.bindAsEventListener(this, element, this.normal);
    this.mouseover = this.toggle.bindAsEventListener(this, element, this.hover);
    Event.observe(element, "mouseout", this.mouseout);
    Event.observe(element, "mouseover", this.mouseover);
  },

  toggle: function(event, element, className) {
    Event.stop(event);
    if (this.options.beforeToggle()) element.className = className;
  },

  getNormalClass: function(element) {
    var className = (this.options.defaultClass || element.className);
    return (className || '');
  },
  
  getHoverClass: function(defaultClass) {
    var className = this.options.hoverClass;
    if (!className) {
      className = defaultClass.split(' ').collect(function(c) {
        return c + 'Hover';
      }).join(' ');
    }  
     return className;
  },

  destroy: function() {
    Event.stopObserving(this.element, 'mouseout', this.mouseout);
    Event.stopObserving(this.element, 'mouseover', this.mouseover);
    this.mouseout = null;
    this.mouseover = null;
  },

  refresh: function() {
    this.destroy();
    this.build(this.element);
  }
}


/**
 * Date
 */
Object.extend(Date.prototype, {
  msPerDay: function() {
    return 24 * 60 * 60 * 1000;
  },

  advance: function(options) {
    return new Date(this.getTime() + this.msPerDay() * options.days);
  },

  days: function() {
    var date = new Date(this.getFullYear(), this.getMonth(), this.getDate(), 0, 0, 0);
    return Math.round(date.getTime() / this.msPerDay());
  },

  toHash: function() {
    return {
      year:  this.getFullYear(),
      month: this.getMonth(),
      day:   this.getDate(),
      hour:  this.getHours(),
      min:   this.getMinutes(),
      sec:   this.getSeconds()
    }
  },

  sameYear: function(date) {
    return this.getFullYear() == date.getFullYear();
  },

  sameMonth: function(date) {
    return this.sameYear(date) && this.getMonth() == date.getMonth();
  },

  sameDate: function(date) {
    return this.sameYear(date) && this.sameMonth(date) && this.getDate() == date.getDate();
  },

  betweenDate: function(start, finish) {
    var myDays = this.days();
    return (start.days() <= myDays && myDays <= finish.days());
  },

  betweenTime: function(start, finish) {
    var myTime = this.getTime();
    return (start.getTime() <= myTime && myTime <= finish.getTime());
  },

  strftime: function(format) {
    return DateUtil.simpleFormat(format)(this);
  }
});


/**
 * DateUtil
 */
var DateUtil = {

  dayOfWeek: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],

  months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],

  daysOfMonth: [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],

  numberOfDays: function(start, finish) {
    return finish.days() - start.days();
  },

  isLeapYear: function(year) {
    if (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0))
      return true;
    return false;
  }, 

  nextDate: function(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1);
  },

  previousDate: function(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() - 1);
  },
  
  afterDays: function(date, after) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + after);
  },
  
  getLastDate: function(year, month) {
    var last = this.daysOfMonth[month];
    if ((month == 1) && this.isLeapYear(year)) {
      return new Date(year, month, last + 1);
    }
    return new Date(year, month, last);
  },
  
  getFirstDate: function(year, month) {
    if (year.constructor == Date) {
      return new Date(year.getFullYear(), year.getMonth(), 1);
    }
    return new Date(year, month, 1);
  },

  getWeekTurn: function(date, firstDWeek) {
    var limit = 6 - firstDWeek + 1;
    var turn = 0;
    while (limit < date) {
      date -= 7;
      turn++;
    }
    return turn;
  },

  toDateString: function(date) {
    return date.toDateString();
  },
  
  toLocaleDateString: function(date) {
    return date.toLocaleDateString();
  },
  
  simpleFormat: function(formatStr) {
    return function(date) {
      var formated = formatStr.replace(/M+/g, DateUtil.zerofill((date.getMonth() + 1).toString(), 2));
      formated = formated.replace(/d+/g, DateUtil.zerofill(date.getDate().toString(), 2));
      formated = formated.replace(/y{4}/g, date.getFullYear());
      formated = formated.replace(/y{1,3}/g, new String(date.getFullYear()).substr(2));
      formated = formated.replace(/E+/g, DateUtil.dayOfWeek[date.getDay()]);
      return formated;
    }
  },

  zerofill: function(date,digit){
    var result = date;
    if(date.length < digit){
      var tmp = digit - date.length;
      for(i=0; i < tmp; i++){
        result = "0" + result;
      }
    }
    return result;
  },

  toDate: function(hash) {
    return new Date(hash.year, hash.month, hash.day, hash.hour || 0, hash.min || 0, hash.sec || 0);
  }
}


/**
 * ZindexManager
 */
var ZindexManager = {
  zIndex: 1000,

  getIndex: function(zIndex) {
    if (zIndex) {
      if (isNaN(zIndex)) {
        zIndex = Element.getMaxZindex() + 1;
      } else if (ZindexManager.zIndex > zIndex) {
        zIndex = ZindexManager.zIndex;
      }
    } else {
      zIndex = ZindexManager.zIndex;
    }
    ZindexManager.zIndex = zIndex + 1;
    return zIndex;
  }
}


/**
 * Modal
 */
var Modal = {
  maskId:          'modalMask',
  maskClass:       'modal_mask',
  maskClassIE:     'modal_mask_ie',
  element:         null,
  snaps:           null,
  listener:        null,
  resizeListener:  null,
  cover:           null,
  excepteds:       null,
  maskCallbacks:   [],
  unmaskCallbacks: [],

  mask: function(excepted) {
    this._mask.callAfterLoading(this, excepted);
  },

  unmask: function() {
//    this._unmask.callAfterLoading(this);
    this._unmask();
  },

  addMaskCallback: function(callback) {
    if (!this.maskCallbacks.any(function(c) { return c == callback; })) {
      this.maskCallbacks.push(callback);
    }
  },

  removeMaskCallback: function(callback) {
    this.maskCallbacks = this.maskCallbacks.reject(function(c) { return c == callback; });
  },

  clearMaskCallback: function() {
    this.maskCallbacks = [];
  },

  addUnmaskCallback: function(callback) {
    if (!this.unmaskCallbacks.any(function(c) { return c == callback; })) {
      this.unmaskCallbacks.push(callback);
    }
  },

  removeUnmaskCallback: function(callback) {
    this.unmaskCallbacks = this.unmaskCallbacks.reject(function(c) { return c == callback; });
  },

  clearUnmaskCallback: function() {
    this.unmaskCallbacks = [];
  },

  _mask: function(excepted) {
    var options = Object.extend({
      cssPrefix: 'custom_',
      zIndex: null
    }, arguments[1] || {});

    if (Modal.element) {
      Modal._snap(excepted);
      Modal._rebuildMask();
    } else {
      Modal.snaps = [];
      Modal.excepteds = [];
      Modal._buildMask(options.cssPrefix);
      Modal.cover = new IECover(Modal.element, {transparent: true});
    }
    Modal._setZindex(excepted, options.zIndex);
    Modal._setFullSize();
    if (!Modal.hasExcepted(excepted)) Modal.excepteds.push(excepted);
    this.maskCallbacks.each(function(callback) { callback(excepted); });
  },

  _unmask: function() {
    if (Modal.element) {
      if (Modal.snaps.length == 0) {
        Element.hide(Modal.element);
        Modal._removeEvent();
        Modal.excepteds = [];
        Element.remove(Modal.element);
        Modal.element = null;
      } else {
        Element.setStyle(Modal.element, {zIndex: Modal.snaps.pop()});
        Modal.excepteds.pop();
      }
    }
    this.unmaskCallbacks.each(function(callback) { callback(); });
  },

  _addEvent: function() {
    if (!Modal.listener) {
      Modal.listener = Modal._handleEvent.bindAsEventListener();
      Modal.resizeListener = Modal._onResize.bindAsEventListener();
    }
    Event.observe(document, "keypress", Modal.listener);
    Event.observe(document, "keydown", Modal.listener);
    Event.observe(document, "keyup", Modal.listener);
    Event.observe(document, "focus", Modal.listener);
    Event.observe(window, "resize", Modal.resizeListener);
  },

  _removeEvent: function() {
    Event.stopObserving(document, "keypress", Modal.listener);
    Event.stopObserving(document, "keydown", Modal.listener);
    Event.stopObserving(document, "keyup", Modal.listener);
    Event.stopObserving(document, "focus", Modal.listener);
    Event.stopObserving(window, "resize", Modal.resizeListener);
  },

  _isMasked: function() {
    return Modal.element && Element.visible(Modal.element);
  },

  _snap: function(excepted) {
    var index = Element.getStyle(Modal.element, 'zIndex');
    if (index && Modal._isMasked() && !Modal.hasExcepted(excepted)) Modal.snaps.push(index);
  },

  _setZindex: function(excepted, zIndex) {
    zIndex = ZindexManager.getIndex(zIndex);
    Element.setStyle(Modal.element, {zIndex:  zIndex});
    excepted = Element.makePositioned($(excepted));
    Element.setStyle(excepted, {zIndex: ++zIndex});
  },

  _setFullSize: function() {
    Modal.element.setStyle({
      width:  Element.getWindowWidth() + 'px',
      height: Element.getWindowHeight() + 'px'
    });
    if (Modal.cover) Modal.cover.resetSize();
  },

  _buildMask: function(cssPrefix) {
    var mask = Builder.node('div', {id: Modal.maskId});
    Modal._setClassNames(mask, cssPrefix);
    document.body.appendChild(mask);
    Modal.element = mask;
    Modal._addEvent();
  },

  _setClassNames: function(element, cssPrefix) {
    var className = (UserAgent.isIE()) ? Modal.maskClassIE : Modal.maskClass;
    Element.addClassName(element, className);
    Element.addClassName(element, cssPrefix + className);
  },

  _rebuildMask: function() {
    document.body.appendChild(Modal.element);
    Element.show(Modal.element);
  },

  _isOutOfModal: function(src) {
    if (!Modal.element) return;
    var limit = Element.getStyle(Modal.element, 'zIndex');
    var zIndex = null;
    while ((src = src.parentNode) && src != document.body) {
      if (src.style && (zIndex = Element.getStyle(src, 'zIndex'))) {
        if (zIndex > limit) {
          return true;
        } else {
          return false;
        }
      }
    }
    return false;
  },

  _handleEvent: function (event) {
    var src = Event.element(event);
    if (!Modal._isOutOfModal(src)) {
      Event.stop(event);
    }
  },

  _onResize: function(event) {
    Modal._setFullSize();
  },

  hasExcepted: function(excepted) {
    return (Modal.excepteds || []).any(function(element) {
      return element.id == excepted.id;
    });
  }
}


/**
 * IECover
 */
var IECover = Class.create();
IECover.src = 'javascript:false;';
IECover.prototype = {
  idSuffix: 'iecover',

  initialize: function(parent) {
    this.options = Object.extend({
      transparent : false,
      padding     : 0
    }, arguments[1] || {});

    if (document.all) {
      parent = $(parent);
      this.id = parent.id.appendSuffix(this.idSuffix);
      this._build(parent);
      this.resetSize();
    }
  },

  resetSize: function() {
    if (this.element) {
      var parent = this.element.parentNode;
      var padding = this.options.padding;
      this.element.width = parent.offsetWidth - padding + 'px';
      this.element.height = Element.getHeight(parent) - padding + 'px';
    }
  },

  _build: function(parent) {
    var padding = this.options.padding / 2;
    var styles = {
      position : 'absolute',
      top      : padding + 'px',
      left     : padding + 'px'
    };
    if (this.options.transparent) styles.filter = 'alpha(opacity=0)';
    if (parent.buildedIECover && $(this.id)) {
      this.element = $(this.id);
    } else {
      this.element = Builder.node('iframe', {src: IECover.src, id: this.id, frameborder: 0});
    }
    Element.setStyle(this.element, styles);
    var firstNode = Element.down(parent, 0);
    if (firstNode) Element.makePositioned(firstNode);
    parent.insertBefore(this.element, parent.firstChild);
    parent.buildedIECover = true;
  }
}

/**
 * UserAgent
 */
var UserAgent = {
  getUserAgent: function() {
    return navigator.userAgent;
  },
  isIE: function() {
    return (document.all && this.getUserAgent().toLowerCase().indexOf('msie') != -1);
  },
  isIE7: function() {
    return (document.all && this.getUserAgent().toLowerCase().indexOf('msie 7') != -1);
  },
  isSafari: function() {
    return (this.getUserAgent().toLowerCase().indexOf('safari') != -1);
  },
  isMac: function() {
    return (this.getUserAgent().toLowerCase().indexOf('macintosh') != -1);
  }
}

/**
 * ShortcutManager
 */
var ShortcutManager = Class.create();
ShortcutManager.prototype = {
  initialize: function() {
    var defaultOptions  = {
      detectKeyup:false,
      initialStarted:true,
      preventDefault:true
    }
    this.options = Object.extend(defaultOptions, arguments[0] || {});
    this.keydownListener    = this.eventKeydown.bindAsEventListener(this);
    if(this.options.detectKeyup) {
      this.keyupListener    = this.eventKeyup.bindAsEventListener(this);
    }
    this.keydownFunc        = new Object();
    this.keydownFunc['a']   = new Object();
    this.keydownFunc['ac']  = new Object();
    this.keydownFunc['as']  = new Object();
    this.keydownFunc['acs'] = new Object();
    this.keydownFunc['c']   = new Object();
    this.keydownFunc['cs']  = new Object();
    this.keydownFunc['n']   = new Object();
    this.keydownFunc['s']   = new Object();
    this.keyupFunc          = new Object();
    this.keyCode            = {
      'backspace':      8,
      'tab':            9,
      'return':        13,
      'enter':         13,
      'pause':         19,
      'break':         19,
      'caps':          20,
      'capslock':      20,
      'esc':           27,
      'escape':        27,
      'space':         32,
      'pageup':        33,
      'pgup':          33,
      'pagedown':      34,
      'pgdn':          34,
      'end':           35,
      'home':          36,
      'left':          37,
      'up':            38,
      'right':         39,
      'down':          40,
      'insert':        45,
      'delete':        46,
      '0':             48,
      '1':             49,
      '2':             50,
      '3':             51,
      '4':             52,
      '5':             53,
      '6':             54,
      '7':             55,
      '8':             56,
      '9':             57,
      'a':             65,
      'b':             66,
      'c':             67,
      'd':             68,
      'e':             69,
      'f':             70,
      'g':             71,
      'h':             72,
      'i':             73,
      'j':             74,
      'k':             75,
      'l':             76,
      'm':             77,
      'n':             78,
      'o':             79,
      'p':             80,
      'q':             81,
      'r':             82,
      's':             83,
      't':             84,
      'u':             85,
      'v':             86,
      'w':             87,
      'x':             88,
      'y':             89,
      'z':             90,
      'f1':           112,
      'f2':           113,
      'f3':           114,
      'f4':           115,
      'f5':           116,
      'f6':           117,
      'f7':           118,
      'f8':           119,
      'f9':           120,
      'f10':          121,
      'f11':          122,
      'f12':          123,
      'numlock':      144,
      'nmlk':         144,
      'scrolllock':   145,
      'scflk':        145,
      'cmd':          224,
      'command':      224
    };
    this.numKeys = {
      96:   48,
      97:   49,
      98:   50,
      99:   51,
      100:  52,
      101:  53,
      102:  54,
      103:  55,
      104:  56,
      105:  57
    };
    if(this.options.initialStarted) {
      this.start();
    } else {
      this.stop();
    }
    Event.observe(document, 'keydown', this.keydownListener);
    if(this.options.detectKeyup) {
      Event.observe(document, 'keyup', this.keyupListener);
    }
  },
  add: function(c1, c2, keyup) {
    if(c1.constructor == Array) {
      var self = this;
      c1.each(
        function(pair) {
          self._add_or_remove_function(pair[0], pair[1], keyup);
        }
      );
    } else {
      this._add_or_remove_function(c1, c2, keyup);
    }
  },
  destroy: function() {
    Event.stopObserving(document, 'keydown', this.keydownListener);
    if(this.options.detectKeyup) {
      Event.stopObserving(document, 'keyup', this.keyupListener);
    }
  },
  eventKeydown: function(event) {
    if(this.executable) {
      var code;
      var key = '';
      event = event || window.event;
      if(event.keyCode) {
        if(event.altKey) {
          key += 'a';
        }
        if(event.ctrlKey) {
          key += 'c';
        }
        if(event.shiftKey) {
          key += 's';
        }
        if(key == '') {
          key = 'n';
        }
        code = this._mergeNumKey(event.keyCode);
        if(this.keydownFunc[key][code]) {
          this.keydownFunc[key][code]();
          if(this.options.preventDefault) {
            Event.stop(event);
          }
        }
      }
    }
  },
  eventKeyup: function(event) {
    if(this.executable) {
      var code;
      event = event || window.event;
      if(event.keyCode) {
        code = this._mergeNumKey(event.keyCode);
        if(this.keyupFunc[code]) {
          this.keyupFunc[code]();
          if(this.options.preventDefault) {
            Event.stop(event);
          }
        }
      }
    }
  },
  remove: function(shortcut) {
    this._add_or_remove_function(shortcut);
  },
  start: function() {
    this.executable = true;
  },
  stop: function() {
    this.executable = false;
  },
  _add_or_remove_function: function(shortcut, callback, keyup) {
    var pressed_key_code;
    var additional_keys = new Array();
    var self = this;
    $A(shortcut.toLowerCase().split("+")).each(
      function(key) {
        if(key == 'alt') {
          additional_keys.push('a');
        } else if(key == 'ctrl') {
          additional_keys.push('c');
        } else if(key == 'shift') {
          additional_keys.push('s');
        } else {
          pressed_key_code = self.keyCode[key];
        }
      }
    );
    var key = additional_keys.sortBy(function(value, index) {return value;}).join('');
    if(key == '') {
      key = 'n';
    }
    if(callback) {
      if(keyup) {
        this.keyupFunc[pressed_key_code] = callback;
      } else {
        this.keydownFunc[key][pressed_key_code] = callback;
      }
    } else {
      if(keyup) {
        this.keyupFunc[pressed_key_code] = null;
      } else {
        this.keydownFunc[key][pressed_key_code] = null;
      }
    }
  },
  _mergeNumKey: function(code) {
    return (this.numKeys[code]) ? this.numKeys[code] : code;
  }
}


/**
 * Function
 */
Function.prototype.callAfterLoading = function() {
  var args = $A(arguments);
  var self = this;
  var object = args.shift() || this;
  if (UserAgent.isIE() && (document.readyState != 'complete')) {
    Event.observe(window, 'load', function() { self.apply(object, args) });
  } else {
    this.apply(object, args);
  }
}


/**
 * SpinelzUtil
 */
var SpinelzUtil = {

  idCount: 0,

  getId: function(idBase) {
    idBase = idBase || '';
    return idBase.appendSuffix(++SpinelzUtil.idCount);
  },

  toAttriteString: function(attributes, frontSpace) {
    var html = attributes.map(function(pair) {
      return pair.key + "='" + pair.value + "'";
    }).join(' ');
    if (frontSpace && (html.length > 0)) html = " " + html;
    return html;
  },

  concat: function(base, suffixes) {
    var hash = {};
    suffixes.each(function(suffix) {
      hash[suffix] = base.appendSuffix(suffix);
    });
    return hash;
  }
}


/**
 * prototype.js
 */
var $A = Array.from = function(iterable) {
  if (!iterable) return [];
  if (iterable.toArray) {
    return iterable.toArray();
  } else {
    var results = [];
    for (var i = 0, len = iterable.length; i < len; i++)
      results.push(iterable[i]);
    return results;
  }
}
