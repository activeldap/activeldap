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


SideBarBox = Class.create();

SideBarBox.className = {
  panelContainer:    'sideBarBox_panelContainer',
  tabContainer:      'sideBarBox_tabContainer',
  title:             'sideBarBox_tabTitle',
  tab:               'sideBarBox_tab',
  tabTopInactive:    'sideBarBox_tabTopInactive',
  tabTopActive:      'sideBarBox_tabTopActive',
  tabMiddleInactive: 'sideBarBox_tabMiddleInactive',
  tabMiddleActive:   'sideBarBox_tabMiddleActive',
  tabBottomInactive: 'sideBarBox_tabBottomInactive',
  tabBottomActive:   'sideBarBox_tabBottomActive'
}

SideBarBox.prototype = {
  
  initialize: function(element) {
    var options = Object.extend({
      selected:     1,
      beforeSelect: function() {return true},
      afterSelect:  Prototype.emptyFunction,
      visible:      false,
      close:        true,
      cssPrefix:    'custom_',
      build:        true
    }, arguments[1] || {});
    
    this.options = options;
    this.element = $(element);
    if (this.options.build) Element.setStyle(this.element, {visibility: 'hidden'});
    
    this.css = CssUtil.getInstance(this.options.cssPrefix, SideBarBox.className);
    this.classNames = this.css.allJoinClassNames();

    this.start();
    Element.setStyle(this.element, {visibility: 'visible'});
  },
  
  start: function() {
    this.tabs = [];
    this.panelContents = [];
    this.tabSets = [];
    
    this.visible = this.options.visible;
    this.selected = (this.options.selected > 0) ? this.options.selected - 1 :  0 ;
    this.selected = (this.visible) ? this.selected : -1;
    
    this.tabId            = this.element.id + '_tab';
    this.tabTopId         = this.tabId + '_top';
    this.tabMiddleId      = this.tabId + '_middle';
    this.tabBottomId      = this.tabId + '_bottom';
    this.tabContainerId   = this.element.id + '_tabContainer';
    this.panelId          = this.element.id + '_panel';
    this.panelContainerId = this.element.id + '_panelContainer';

    this.ids = [];
    this.holder = [];
    if (this.options.build) this.buildTabBox();  

    this.tabContainer = $(this.tabContainerId);  
    this.panelContainer = $(this.panelContainerId);
    this.tabs = this.tabs.collect(function(tab) { return $(tab); });
    this.panelContents = this.panelContents.collect(function(panel) { return $(panel); });

    if (this.options.build) {
      this.selectTab();
      this.setEvent();
      this.appendElements();
    }
  },

  setEvent: function() {
    this.ids.each(function(tab) {
      Event.observe(tab, 'click', this.selectTab.bindAsEventListener(this));
    }.bind(this));
  },

  appendElements: function() {
    this.holder.each(function(set) {
      $(this.tabMiddleId + set.number).appendChild(set.tab);
      this.panelContents[set.number].appendChild(set.content);
    }.bind(this));
  },
  
  buildTabBox: function() {
    var tabContainer =
      "<div id='" + this.tabContainerId + "' class='" + this.classNames['tabContainer'] + "'>";
    var panelContainer =
      "<div id='" + this.panelContainerId + "' class='" + this.classNames['panelContainer'] + "'>";

    var tabSetCount = 0;
    $A(this.element.childNodes).each(function(node) {
      if (Element.isElementNode(node)) {
        var tabSet = this.buildTabSet(node, tabSetCount);
        tabContainer += tabSet.tab;
        panelContainer += tabSet.panel;
        tabSetCount++;
      }
    }.bind(this));

    tabContainer += "</div>";
    panelContainer += "</div>";
    this.addContainers(panelContainer, tabContainer);
  },

  addContainers : function(panelContainer, tabContainer) {
    this.element.innerHTML = panelContainer + tabContainer + "<div style='clear: left'></div>";
  },

  buildTabSet: function(element, i) {
    var nodes = Element.getChildNodesWithoutWhitespace(element);
    this.holdElements(nodes[0], nodes[1], i);
    return {
      tab: this.buildTab(nodes[0], i),
      panel: this.buildPanel(nodes[1], i)
    }
  },
  
  buildTab: function(tab, i) {
    var tabId = this.tabId + i;
    this.ids.push(tabId);
    this.tabs[i] = tabId;

    var title = tab.title;
    title = title ? " title='" + title + "'" : '';

    var html =
      "<div id='" + tabId + "' class='" + this.classNames['tab'] + "'" + title + ">" +
        "<div id='" + this.tabTopId + i + "' class='" + this.classNames['tabTopInactive'] + "'></div>" +
        "<div id='" + this.tabMiddleId + i + "' class='" + this.classNames['tabMiddleInactive'] + "'>" +
        "</div>" +
        "<div id='" + this.tabBottomId + i + "' class='" + this.classNames['tabBottomInactive'] + "'></div>" +
      "</div>";
    return html;
  },
  
  buildPanel: function(panelContent, i) {
    var id = this.panelId + i;
    this.panelContents[i] = id;
    return "<div id='" + id + "' style='display: none;'></div>";
  },

  holdElements: function(tab, content, number) {
    this.holder.push({number: number, tab: tab, content: content});
    var tmpParent = document.createDocumentFragment();
    tmpParent.appendChild(tab);
    tmpParent.appendChild(content);
  },
  
  selectTab: function(e) {
    if (!this.options.beforeSelect()) return;
    if (!e) {
      this.setTabActive(this.tabs[this.selected]);
      Element.show(this.panelContents[this.selected]);
      return;
    }

    var currentPanel = this.panelContents[this.selected];
    var currentTab = this.tabs[this.selected];

    var targetElement = null;
    if (e.nodeType) {
      targetElement = e; 
    } else {
      targetElement = Event.element(e);
    }
    var targetIndex = this.getTargetIndex(targetElement);
    var targetPanel = this.panelContents[targetIndex];
    var targetTab = this.tabs[targetIndex];
    if (this.visible) {
      if (targetTab.id == currentTab.id) {
        if (this.options.close) {
          Effect.SlideRightOutOfView(this.panelContainer);
          this.visible = false;
          this.selected = -1;
          this.setTabInactive(currentTab);
          Element.toggle(targetPanel);
        }
      } else {
        this.setTabActive(targetTab);
        this.setTabInactive(currentTab);
        Element.toggle(currentPanel);
        Element.toggle(targetPanel);
        this.selected = targetIndex;
      }
    } else {
      this.setTabActive(targetTab);
      Element.toggle(targetPanel);
      Effect.SlideRightIntoView(this.panelContainer);
      this.visible = true;  
      this.selected = targetIndex;
    }
    this.options.afterSelect(targetPanel, currentPanel);
  },
  
  setTabActive: function(tab) {
    var tabChildren = Element.getTagNodes(tab);
    this.css.refreshClassNames(tabChildren[0], 'tabTopActive');
    this.css.refreshClassNames(tabChildren[1], 'tabMiddleActive');
    this.css.refreshClassNames(tabChildren[2], 'tabBottomActive');
  },
  
  setTabInactive: function(tab) {
    var tabChildren = Element.getTagNodes(tab);
    this.css.refreshClassNames(tabChildren[0], 'tabTopInactive');
    this.css.refreshClassNames(tabChildren[1], 'tabMiddleInactive');
    this.css.refreshClassNames(tabChildren[2], 'tabBottomInactive');
  },
  
  getTargetIndex: function(element) {
    while(element) {
      if (element.id && element.id.indexOf(this.tabId, 0) >= 0) {
        var index = element.id.substring(this.tabId.length);
        if (!isNaN(index)) {
          return index;
        }
      }
      element = element.parentNode;
    }
  },

  hasNextTab: function() {
    return this.getNextTab() ? true : false;
  },

  hasPreviousTab: function() {
    return this.getPreviousTab() ? true : false;
  },

  getNextTab: function() {
    return Element.next(this.getCurrentTab());
  },

  getPreviousTab: function() {
    return Element.previous(this.getCurrentTab());
  },

  selectNextTab: function() {
    this.selectTab(this.getNextTab());
  },

  selectPreviousTab: function() {
    this.selectTab(this.getPreviousTab());
  },

  tabCount: function() {
    return this.tabs.inject(0, function(i, t) {
      return t ? ++i : i;
    })
  },

  getCurrentPanel: function() {
    return this.panelContents[this.selected];
  },

  getCurrentTab: function() {
    return this.tabs[this.selected];
  }
}
