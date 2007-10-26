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

TabBox = Class.create();
TabBox.className = {
  tabBox:            'tabBox_tabBox',
  panelContainer:    'tabBox_panelContainer',
  tabContainer:      'tabBox_tabContainer',
  tabBar:            'tabBox_tabBar',
  tab:               'tabBox_tab',
  tabLeftInactive:   'tabBox_tabLeftInactive',
  tabLeftActive:     'tabBox_tabLeftActive',
  tabMiddleInactive: 'tabBox_tabMiddleInactive',
  tabMiddleActive:   'tabBox_tabMiddleActive',
  tabRightInactive:  'tabBox_tabRightInactive',
  tabRightActive:    'tabBox_tabRightActive',
  tabTitle:          'tabBox_tabTitle',
  closeButton:       'tabBox_closeButton'
}

TabBox.prototype = {
  initialize: function(element) {
    var options = Object.extend({
      selected:         1,
      cssPrefix:        'custom_',
      beforeSelect:     function() { return true },
      afterSelect:      Prototype.emptyFunction,
      afterSelectOnce:  Prototype.emptyFunction,
      onRemove:         function() { return true },
      sortable:         false,
      closeButton:      false,
      afterSort:        Prototype.emptyFunction,
      onSort:           Prototype.emptyFunction,
      lazyLoadUrl:      [],
      onLazyLoad:       Prototype.emptyFunction,
      afterLazyLoad:    Prototype.emptyFunction,
      lazyLoadFailure:  Prototype.emptyFunction,
      failureLimitOver: Prototype.emptyFunction,
      failureLimit:     5,
      tabRow:           null,
      titleLength:      null
    }, arguments[1] || {});
    
    this.options = options;
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    Element.hide(this.element);
    this.selected = (this.options.selected > 0) ? this.options.selected - 1 :  0 ;
    
    this.css = CssUtil.getInstance(this.options.cssPrefix, TabBox.className);
    this.classNames = this.css.allJoinClassNames();
    this.css.addClassNames(this.element, 'tabBox');
        
    this.start();
    Element.setStyle(this.element, {visibility: 'visible'});
    Element.show(this.element);

    if (this.options.lazyLoadUrl.length > 0) this.lazyLoad(0);
  },
  
  start: function() {
    this.tabs = [];
    this.panelList = [];

    this.tabId            = this.element.id + '_tab';
    this.tabLeftId        = this.tabId + '_left';
    this.tabMiddleId      = this.tabId + '_middle';
    this.tabRightId       = this.tabId + '_right';
    this.tabContainerId   = this.element.id + '_tabContainer';
    this.panelId          = this.element.id + '_panel';
    this.panelContainerId = this.element.id + '_panelContainer';
    this.tabTitleId       = this.element.id + '_tabTitle';
    
    this.ids = [];
    this.holder = [];
    this.build();  
    this.tabs = this.tabs.collect(function(tab) { return $(tab) });
    this.panelList = this.panelList.collect(function(panel) { return $(panel) });
    this.tabContainer = $(this.tabContainerId);
    this.panelContainer = $(this.panelContainerId);
    this.selectTab();
    this.setEvent();
    this.appendElements();
    if (this.options.sortable) this.setDrag();
  },

  setDrag: function() {
    Sortable.create(this.tabContainerId, {
      tag:         'div',
      overlap:     'horizontal',
      constraint:  'horizontal',
      onChange:    this.options.onSort,
      onUpdate:    this.options.afterSort,
      starteffect: Prototype.emptyFunction,
      endeffect:   Prototype.emptyFunction
    });
  },

  setEvent: function() {
    this.ids.each(function(idSet) {
      Event.observe(idSet.tab, 'click', this.selectTab.bindAsEventListener(this));
      Event.observe(idSet.tab, 'mouseover', this.onMouseOver.bindAsEventListener(this));
      Event.observe(idSet.tab, 'mouseout', this.onMouseOut.bindAsEventListener(this));
      if (this.options.closeButton) {
        Event.observe(idSet.button, 'click', this.onRemove.bindAsEventListener(this));
      }
    }.bind(this));
  },

  appendElements: function() {
    this.holder.each(function(set) {
      $(this.tabTitleId + set.number).appendChild(set.tab);
      this.panelList[set.number].appendChild(set.content);
    }.bind(this));
  },
  
  build: function() {
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
    this.element.innerHTML = tabContainer +
      "<div class='" + this.classNames['tabBar'] + "'></div>" + panelContainer;
  },

  buildTabSet: function(element, i) {
    var nodes = Element.getChildNodesWithoutWhitespace(element);
    this.holdElements(nodes[0], nodes[1], i);
    return {
      tab:  this.buildTab(nodes[0], i, Element.attributeHTML(element, 'onclick')),
      panel: this.buildPanel(nodes[1], i)
    };
  },

  buildTab: function(tab, i, events) {
    var tabId = this.tabId + i;
    var ids = {tab: tabId};
    this.ids.push(ids);
    this.tabs[i] = tabId;

    var button = "";
    if (this.options.closeButton) {
      var buttonId = this.element.id.appendSuffix('closeButton_' + i);
      ids.button = buttonId;
      button = "<div id='" + buttonId + "' class='" + this.classNames['closeButton'] + "'></div>";
    }

    var tabStyle = "";
    if (this.options.tabRow && !isNaN(this.options.tabRow) && ((i % this.options.tabRow) == 0)) {
      tabStyle = " style='clear: left; float: none;'";
    }

    var tabText = this.getTabText(tab).escapeHTML().replace(/"/g, '&quot;');
    this.setTabText(tab, this.chopTabText(tabText));

    var html =
      "<div id='" + tabId + "' class='" + this.classNames['tab'] + "'" + tabStyle + " " + events + ">" +
        "<div id='" + this.tabLeftId + i + "' class='" + this.classNames['tabLeftInactive'] + "'></div>" +
        "<div id='" + this.tabMiddleId + i + "' class='" + this.classNames['tabMiddleInactive'] + "'>" +
          '<div id="' + this.tabTitleId + i + '" class="' + this.classNames['tabTitle'] + '" title="' + tabText + '">' +
          "</div>" +
          button +
        "</div>" +
        "<div id='" + this.tabRightId + i + "' class='" + this.classNames['tabRightInactive'] + "'></div>" +
      "</div>";
    return html;
  },

  setTabText: function(element, text) {
    if (Element.isTextNode(element)) {
      element.nodeValue = text;
    } else if (Element.isElementNode(element)) {
      element.innerHTML = text;
    }
  },

  getTabText: function(element) {
    if (Element.isTextNode(element)) {
      textNode = element;
    } else if (Element.isElementNode(element)) {
      textNode = Element.getTextNodes(element, true)[0];
    } else {
      return '';
    }
    return textNode.nodeValue.replace(/(^(\s)*) | ((\s)*$)/, '');
  },

  chopTabText: function(title) {
    if (this.options.titleLength && !isNaN(this.options.titleLength)) {
      title = title.substring(0, this.options.titleLength);
    }
    return title;
  },

  buildPanel: function(panelContent, i) {
    var id = this.panelId + i;
    this.panelList[i] = id;
    return "<div id='" + id + "' style='display: none;'></div>";
  },

  holdElements: function(tab, content, number) {
    this.holder.push({number: number, tab: tab, content: content});
    var tmpParent = document.createDocumentFragment();
    tmpParent.appendChild(tab);
    tmpParent.appendChild(content);
  },
  
  selectTab: function(e){
    if (!this.options.beforeSelect()) return;
    if (!e) {
      this.setTabActive(this.tabs[this.selected]);
      Element.show(this.panelList[this.selected]);
      return;
    }
    var currentPanel = this.getCurrentPanel();
    var currentTab = this.getCurrentTab();
    
    var targetElement = null;
    if (e.nodeType) {
      targetElement = e; 
    } else {
      targetElement = Event.element(e);
    }
    var targetIndex = this.getTargetIndex(targetElement);
    if (targetIndex == this.selected) {
      return;
    }
    var targetPanel = this.panelList[targetIndex];
    var targetTab = this.tabs[targetIndex];
    
    if (currentTab) this.setTabInactive(currentTab);
    this.setTabActive(targetTab);

    if (currentPanel) Element.toggle(currentPanel);
    Element.toggle(targetPanel);

    this.selected = targetIndex;
    this.options.afterSelect(targetPanel, currentPanel);
    if (!targetPanel.selected) {
      this._callAfterSelectOnce(targetPanel);
      targetPanel.selected = true;
    }
  },
  
  setTabActive: function(tab) {
    var tabChildren = tab.childNodes;
    this.css.refreshClassNames(tabChildren[0], 'tabLeftActive');
    this.css.refreshClassNames(tabChildren[1], 'tabMiddleActive');
    this.css.refreshClassNames(tabChildren[2], 'tabRightActive');
  },
  
  setTabInactive: function(tab) {
    var tabChildren = tab.childNodes;
    this.css.refreshClassNames(tabChildren[0], 'tabLeftInactive');
    this.css.refreshClassNames(tabChildren[1], 'tabMiddleInactive');
    this.css.refreshClassNames(tabChildren[2], 'tabRightInactive');
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

  onRemove: function(event) {
    Event.stop(event);
    var element = Event.element(event);
    var index = this.getTargetIndex(element);
    var tab = this.tabs[index];
    if (this.options.onRemove(tab)) {
      this.remove(tab);
    }
  },

  remove: function(tab) {
    if (tab) {
      var index = this.getTargetIndex(tab);
      var nextActiveTab = this.getNextTab();
      if (!nextActiveTab) nextActiveTab = this.getPreviousTab();
      Element.remove(tab);
      Element.remove(this.panelList[index]);
      this.tabs[index] = null;
      this.panelList[index] = null;
  
      if (index == this.selected) {
        if (nextActiveTab) {
          this.selectTab(nextActiveTab);
        }
      }
    }
  },

  addByElement: function(element) {
    this.holder = [];
    this.ids = [];
    this.contents = [];
    var tabSet = this.buildTabSet($(element), this.tabs.length);
    this.tabContainer.appendChild(tabSet.tab.toElement());
    this.panelContainer.appendChild(tabSet.panel.toElement());
    this.tabs[this.tabs.length - 1] = $(this.tabs.last());
    this.panelList[this.panelList.length - 1] = $(this.panelList.last());
    this.setEvent();
    this.appendElements();
    if (this.options.sortable) this.setDrag();
  },

  add: function(title, content) {
    var contents = [];
    var node = Builder.node('div');
    node.innerHTML = title;
    contents.push(node);
    node = Builder.node('div');
    node.innerHTML = content;
    contents.push(node);
    this.addByElement(Builder.node('div', contents));
  },

  lazyLoad: function(index) {
    this.errorCount = 0;
    this.loadedList = [];
    this.load(index);
  },

  load: function(index) {
    var container = this.panelList[index];
    var url = this.options.lazyLoadUrl[index];
    var self = this;
    if (container && url) {
      new Ajax.Updater(
        {success: container},
        url,
        {
          onSuccess: function() {
            self.setLoaded(index);
            self.options.onLazyLoad(container, self);
            self.load(++index);
            if (self.isFinishLazyLoad()) self.options.afterLazyLoad(self);
          },
          onFailure: function() {
            self.errorCount++;
            self.options.lazyLoadFailure(container, self);
            if (self.errorCount <= self.options.failureLimit) {
              self.load(index);
            } else {
              self.options.failureLimitOver(self);
            }
          },
          asynchronous: true, 
          evalScripts: true
        }
      );
    }
  },

  isFinishLazyLoad: function() {
    return this.loadedList.length == this.panelList.length;
  },

  setLoaded: function(i) {
    this.loadedList.push(i);
  },

  onMouseOver: function(event) {
    var targetElement = Event.element(event);
    var targetIndex = this.getTargetIndex(targetElement);
    if (targetIndex != this.selected) {
      var targetTab = this.tabs[targetIndex];
      this.setTabActive(targetTab);
    }
  },

  onMouseOut: function(event) {
    var targetElement = Event.element(event);
    var targetIndex = this.getTargetIndex(targetElement);
    if (targetIndex != this.selected) {
      var targetTab = this.tabs[targetIndex];
      this.setTabInactive(targetTab);
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
    return this.panelList[this.selected];
  },

  getCurrentTab: function() {
    return this.tabs[this.selected];
  },

  _callAfterSelectOnce: function(targetPanel) {
    var func = this.options.afterSelectOnce;
    if (!func) return;

    if (func.constructor != Function) {
      if (func.constructor == Array) {
        func = func[this.panelList.indexOf(targetPanel)];
      } else {
        func = func[this.panelList.indexOf(targetPanel).succ()];
      }
    }
    if (func) func(targetPanel);
  }
}
