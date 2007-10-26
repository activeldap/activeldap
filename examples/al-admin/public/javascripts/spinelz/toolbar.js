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

var ToolBar = Class.create();
ToolBar.className = {
  container : 'toolbar_container',
  containerLeft : 'toolbar_containerLeft',
  containerMiddle : 'toolbar_containerMiddle',
  containerRight : 'toolbar_containerRight', 
  toolbarItem : 'toolbar_item',
  toolbarItemHover : 'toolbar_itemHov',
  toolbarItemPres : 'toolbar_itemPres',
  toolbarContent : 'toolbar_content',
  toolbarContentPres: 'toolbar_contentPres'
}

ToolBar.prototype = {

  initialize: function(element) {
    var options = Object.extend({
      cssPrefix : 'custom_'
    }, arguments[1] || {});
    
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    Element.hide(this.element);
    this.options = options;
    
    var customCss = CssUtil.appendPrefix(this.options.cssPrefix, ToolBar.className);
    this.classNames = new CssUtil([ToolBar.className, customCss]);
    
    this.build();
    Element.setStyle(this.element, {visibility: 'visible'});
    Element.show(this.element);
  },
  
  build: function() {
//    Element.cleanWhitespace(this.element);
    this.classNames.addClassNames(this.element, 'container');
    var iconList = this.element.childNodes;    
    
    var containerLeft = Builder.node('div');
    this.classNames.addClassNames(containerLeft, 'containerLeft');
    
    this.containerMiddle = Builder.node('div');
    this.classNames.addClassNames(this.containerMiddle, 'containerMiddle');
    
    var containerRight = Builder.node('div');
    this.classNames.addClassNames(containerRight, 'containerRight');
    
    var removeList = [];
    var toolbar = this; 
    $A(iconList).each(function(i) {
      if (i.nodeType != 1) {
        throw $continue;
      }
      toolbar.buildIcon(i);
    });
    
    this.element.appendChild(containerLeft);
    this.element.appendChild(this.containerMiddle);
    this.element.appendChild(containerRight);
  },
  
  buildIcon: function(icon) {
    var toolbarItem = Builder.node('div');
    this.classNames.addClassNames(toolbarItem, 'toolbarItem');
    
    var toolbarContent = Builder.node('div');
    this.classNames.addClassNames(toolbarContent, 'toolbarContent');
    
    toolbarContent.appendChild(icon);
    toolbarItem.appendChild(toolbarContent);
    this.containerMiddle.appendChild(toolbarItem);
    this.setHovEvent(toolbarItem);
    this.setPresEvent(toolbarItem);
  },
  
  addIcon: function(options) {
    var iconOptions = Object.extend({
      id : 'newIcon',
      src : 'url',
      alt : 'icon',
      width: 15,
      height: 15
    }, arguments[0] || {});
    if (!$(iconOptions.id)) {
      var icon = Builder.node('img', {id: iconOptions.id, src: iconOptions.src, alt: iconOptions.alt, style: 'width: ' + iconOptions.width + 'px; height: ' + iconOptions.height + 'px;'});
      this.buildIcon(icon);
    }
  },
  
  removeIcon: function(icon) {
    var target = $(icon);
    if (target) {
      var itemNode = target.parentNode.parentNode;
      Element.remove(itemNode);
    } 
  },    

  addEvent: function(icon, eventName, func) {
    var target = $(icon);
    if (target) {
      var itemNode = target.parentNode.parentNode;
      Event.observe(itemNode, eventName, func);
    }
  },
  
  removeEvent: function(icon, eventName, func) {
    var target = $(icon);
    if (target) {
      var itemNode = target.parentNode.parentNode;
      Event.stopObserving(itemNode, eventName, func);
    }
  },
  setHovEvent: function(element) {
    Event.observe(element, "mouseout", this.toggleItemClass(element, 'toolbarItem').bindAsEventListener(this));
    Event.observe(element, "mouseover", this.toggleItemClass(element, 'toolbarItemHover').bindAsEventListener(this));
    Event.observe(element, "mouseout", this.toggleItemClass(element.childNodes[0], 'toolbarContent').bindAsEventListener(this));
  },
  
  setPresEvent: function(element) {
    Event.observe(element, "mousedown", this.toggleItemClass(element, 'toolbarItemPres').bindAsEventListener(this));
    Event.observe(element, "mouseup", this.toggleItemClass(element, 'toolbarItem').bindAsEventListener(this));
    Event.observe(element, "mousedown", this.toggleItemClass(element.childNodes[0], 'toolbarContentPres').bindAsEventListener(this));
    Event.observe(element, "mouseup", this.toggleItemClass(element.childNodes[0], 'toolbarContent').bindAsEventListener(this));
  },
  
  toggleItemClass: function(target, className) {
    return function() {
      this.classNames.refreshClassNames(target, className);
    }
  }
}
