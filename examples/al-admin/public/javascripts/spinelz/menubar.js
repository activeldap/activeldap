// Copyright (c) 2005 spinelz.org (http://script.spinelz.org/)
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

var MenuBar = Class.create();
MenuBar.cssNames = {
  container:        'menubar',
  menu:             'menubar_menu',
  menuBody:         'menubar_menuBody',
  menuBodyHover:    'menubar_menuBodyHover',
  subMenu:          'menubar_subMenu',
  subMenuBody:      'menubar_subMenuBody',
  subMenuBodyHover: 'menubar_subMenuBodyHover',
  subMenuContainer: 'menubar_menuContainer',
  dirMark:          'menubar_dirMark'
}

MenuBar.idSuffixes = ['topContaier', 'menu', 'body'];

MenuBar.mark = {
  dir: '>>'
}

MenuBar.prototype = {

  initialize: function(element) {
    this.options = Object.extend({
      hideOnClickSubmenu: true,
      cssPrefix:          'custom_'
    }, arguments[1] || {});

    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    Element.hide(this.element);
    
    this.classNames = CssUtil.getInstance(
      this.options.cssPrefix, MenuBar.cssNames).allJoinClassNames();
    this.baseIds = SpinelzUtil.concat(this.element.id, MenuBar.idSuffixes);
    this.menuIds = [];
    this.clicked = [];

    this.element.innerHTML = this.build(this.element);
    this.menubar = $(this.baseIds.topContaier);
    this.setEvent();
    
    Event.observe(document, "click", this.hideAllTrigger(this.menubar).bindAsEventListener(this));
    Element.setStyle(this.element, {visibility: 'visible'});
    Element.show(this.element);
  },

  build: function(element) {
    var menuNodes = $A(element.childNodes).inject('', function(nodes, node) {
      return nodes + (Element.isElementNode(node) ? this.buildMenu(node, 'menu') : '');
    }.bind(this));
    return "<div id='" + this.baseIds.topContaier + "'class='" + this.classNames['container'] + "'>" + menuNodes + "</div>";
  },

  buildMenu: function(element, classKey) {
    var bodyText = '';
    var subMenuHtml = '';
    $A(element.childNodes).each(function(node) {
      if (Element.isTextNode(node)) {
        bodyText += node.nodeValue;
      } else if (Element.isElementNode(node)) {
        if (Element.hasTagName(node, 'div')) {
          subMenuHtml += this.buildMenu(node, 'subMenu');
        } else {
          bodyText += Element.outerHTML(node);
        }
      }
    }.bind(this));

    var dirMark = '';
    if (subMenuHtml != '') {
      if (classKey == 'subMenu') {
        dirMark = "<div class='" + this.classNames['dirMark'] + "'>" + MenuBar.mark.dir + "</div>";
      }
      subMenuHtml =
        "<div style='visibility: hidden;' class='" + this.classNames['subMenuContainer'] + "'>" +
          subMenuHtml +
        "</div>";
    }

    var menuId = SpinelzUtil.getId(this.baseIds.menu);
    var bodyId = SpinelzUtil.getId(this.baseIds.body);
    this.menuIds.push({menu: menuId, body: bodyId});

    var html = 
      "<div id='" + menuId + "'class='" + this.classNames[classKey] + "'>" +
        "<div id='" + bodyId + "' class='" + this.classNames[classKey + 'Body'] + "'>" +
          bodyText + dirMark +
        "</div>" +
        subMenuHtml +
      "</div>";
    return html;
  },

  setEvent: function() {
    this.menuIds.each(function(idSet) {
      new Hover(idSet.body);
      Event.observe(idSet.menu, "click", this.onClick.bindAsEventListener(this, $(idSet.body)));
    }.bind(this));
  },
  
  onClick: function(event, menuBody) {
    var menu = menuBody.parentNode;
    var parentContainer = this.getParentContainer(menu);
    
    var container = this.getContainer(menu);
    var className = MenuBar.cssNames.menu;
    if (Element.hasClassName(menu, className)) {
      if (this.clicked.length > 0) {
        this.hideAll(this.menubar);
        this.clicked = [];
      }
      if (container) this.showAtBottom(container, menuBody);

    } else {
      if (container) {
        var lastMenuBody = this.clicked.pop();
        var lastMenu = lastMenuBody.parentNode;
        var lastContainer = this.getContainer(lastMenu);
        var lastParentContainer = this.getParentContainer(lastMenu);
        
        if (lastMenu == menu) {
          this.hide(container);
        } else if (Element.hasClassName(lastContainer, MenuBar.cssNames.container)) {
          this.clicked.push(last);
        } else if (lastParentContainer == parentContainer) {
          this.hide(lastContainer);
        } else {
          this.clicked.push(lastMenuBody);
        }
        this.showAtLeft(container, menu);
      } else if (this.options.hideOnClickSubmenu) {
        this.hideAll(this.menubar);
      }
    }
    
    if (container) this.clicked.push(menuBody);
    Event.stop(event);
  },
  
  showAtBottom: function(contents, menuBody) {
    var offset = Position.positionedOffset(menuBody);
    var height = 0;
      
    if (menuBody.style.height) height = Element.getHeight(menuBody);
    else height = menuBody.clientHeight;
    height += offset[1];
    height += (UserAgent.isIE()) ? 4 : 3;
      
    contents.style.top = height + 'px';
    contents.style.left = offset[0] + 'px';
      
    this.show(contents);
  },
  
  showAtLeft: function(contents, menuBody) {
    var offset = Position.positionedOffset(menuBody);
    
    contents.style.top = (offset[1] - 1) + 'px';
    contents.style.left = (offset[0] + menuBody.offsetWidth + 2) + 'px';
    
    this.show(contents);
  },

  hideAllTrigger: function(element) {
    return function(event) {
      if (!this.isMenuElement(Event.element(event))) this.hideAll(element);
    }
  },
  
  hideAll: function(element) {
    var nodes = element.childNodes;
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].nodeType == 1) {
        if (Element.hasClassName(nodes[i], MenuBar.cssNames.subMenuContainer)) {
          this.hide(nodes[i]);
        }
          
        this.hideAll(nodes[i]);
      }
    }
  },
  
  show: function(element) {
    element.style.visibility = 'visible';
  }, 
  
  hide: function(element) {
    element.style.visibility = 'hidden';
  },
  
  getContainer: function(element) {
    
    if (!element) return;
    return document.getElementsByClassName(MenuBar.cssNames.subMenuContainer, element)[0];
  },
  
  getParentContainer: function(element) {
    var container = Element.getParentByClassName(MenuBar.cssNames.subMenuContainer, element);
    if (!container) {
      container = Element.getParentByClassName(MenuBar.cssNames.container, element);
    }
    
    return container;
  },

  isMenuElement: function(element) {
    return Element.hasClassName(element, MenuBar.cssNames.menuBodyHover)
      || Element.hasClassName(element, MenuBar.cssNames.subMenuBodyHover)
      || Element.hasClassName(element, MenuBar.cssNames.dirMark);
  }
}
