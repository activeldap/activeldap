// Copyright (c) 2005 spinelz.org (http://script.spinelz.org)
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


Accordion = Class.create();
Accordion.className = {
  accordion : 'accordion',
  panel: 'accordion_panel',
  tab : 'accordion_tab',
  tabLeftInactive : 'accordion_tabLeftInactive',
  tabLeftActive: 'accordion_tabLeftActive',
  tabMiddleInactive : 'accordion_tabMiddleInactive',
  tabMiddleActive : 'accordion_tabMiddleActive',
  tabRightInactive : 'accordion_tabRightInactive',
  tabRightActive : 'accordion_tabRightActive'
}

Accordion.prototype = {
  
  initialize: function(element) {
    var options = Object.extend({
      cssPrefix: 'custom_',
      selected: 1,
      duration: 0.5
    }, arguments[1] || {});
    
    this.options = options;
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    Element.hide(this.element);

    var customCss = CssUtil.appendPrefix(this.options.cssPrefix, Accordion.className);
    this.classNames = new CssUtil([Accordion.className, customCss]);
    
    this.classNames.addClassNames(this.element, 'accordion');
    
    this.selected = (this.options.selected > 0) ? this.options.selected - 1 :  0 ;
    this.start();
    
    Element.setStyle(this.element, {visibility: 'visible'});
    Element.show(this.element);
    this.effecting = false;
  },
  
  start: function() {
    this.tabs = [];
    this.panels = [];
    this.panelList = [];

    this.tabId = this.element.id + '_tab';
    this.tabLeftId = this.tabId + '_left';
    this.tabMiddleId = this.tabId + '_middle';
    this.tabRightId = this.tabId + '_right';
    this.panelId = this.element.id + '_panel';
    
    this.build();  
  },  
  
  build: function() {
    Element.cleanWhitespace(this.element);
    this.panelList = this.element.childNodes;
    
    for (var i = 0; i < this.panelList.length; i++) {
      if (this.panelList[i].nodeType != 1) {
        Element.remove(this.panelList[i]);
        i--;
        continue;
      }
      Element.cleanWhitespace(this.panelList[i]);
      var navSet = this.panelList[i].childNodes;
      this.buildTab(navSet[0], i);
      this.buildPanel(navSet[0], i);
    }
    this.selectTab();
  },
  
  
  buildTab: function(tabTitle, i) { 
    var tab = Builder.node('div', {id:this.tabId + i});
    this.classNames.addClassNames(tab, 'tab');    
    var tabLeft = Builder.node('div', {id:this.tabLeftId + i});
    var tabMiddle = Builder.node('div', {id:this.tabMiddleId + i});
    tabMiddle.appendChild(tabTitle);
    var tabRight = Builder.node('div', {id:this.tabRightId + i});
    
    tab.appendChild(tabLeft);
    tab.appendChild(tabMiddle);
    tab.appendChild(tabRight);
    Event.observe(tab, 'click', this.selectTab.bindAsEventListener(this));

    this.tabs[i] = tab;
    this.setTabInactive(tab);
    this.panelList[i].appendChild(tab);
  },
  
  buildPanel: function(panelContent, i) {
    var panel = Builder.node('div', {id:this.panelId + i});
    this.classNames.addClassNames(panel, 'panel');
    
    panel.appendChild(panelContent);
    Element.hide(panel);
    this.panels[i] = panel;
    this.panelList[i].appendChild(panel);
  },
  
  selectTab: function(e) {
    if (this.effecting) return;
    if (!e) {
      if (!this.panels[this.selected]) this.selected = 0;
      Element.show(this.panels[this.selected]);
      this.setTabActive(this.tabs[this.selected]);
      return;
    }

    var targetElement = Event.element(e);
    var targetIndex = this.getTargetIndex(targetElement);
    if (targetIndex == this.selected) return;
            
    var currentPanel = this.panels[this.selected];
    var targetPanel = this.panels[targetIndex];
    this.setTabInactive(this.tabs[this.selected]);
    this.setTabActive(this.tabs[targetIndex]);

    this.effecting = true;
    new Effect.Parallel(
      [
        new Effect.BlindUp(currentPanel, {sync: true}),
        new Effect.BlindDown(targetPanel, {sync: true})
      ],
      {
        duration:    this.options.duration,
        beforeStart: function() { this.effecting = true; }.bind(this),
        afterFinish: function() { this.effecting = false; }.bind(this)
      }
    );

    this.selected = targetIndex;  
  },
  
  setTabActive: function(tab) {
    var tabChildren = tab.childNodes;

     this.classNames.refreshClassNames(tabChildren[0], 'tabLeftActive');
     this.classNames.refreshClassNames(tabChildren[1], 'tabMiddleActive');
     this.classNames.refreshClassNames(tabChildren[2], 'tabRightActive');
  },
  
  setTabInactive: function(tab) {
    var tabChildren = tab.childNodes;
    
    this.classNames.refreshClassNames(tabChildren[0], 'tabLeftInactive');
    this.classNames.refreshClassNames(tabChildren[1], 'tabMiddleInactive');
    this.classNames.refreshClassNames(tabChildren[2], 'tabRightInactive');
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
  }
}
