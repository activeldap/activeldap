var Switcher = Class.create();
Switcher.classNames = {
  open:  'switcher_state_open',
  close: 'switcher_state_close',
  sw:    'switcher_switch'
}
Switcher.prototype = {
  initialize: function(sw, content) {
    this.options = Object.extend({
      open:        false,
      duration:    0.4,
      beforeOpen:  Prototype.emptyFunction,
      afterOpen:   Prototype.emptyFunction,
      beforeClose: Prototype.emptyFunction,
      afterClose:  Prototype.emptyFunction,
      effect:      false,
      cssPrefix:   'custom_',
      subSwitch:   []
    }, arguments[2] || {});

    this.sw = $(sw);
    this.content = $(content);

    var customCss = CssUtil.appendPrefix(this.options.cssPrefix, Switcher.classNames);
    this.classNames = new CssUtil([Switcher.classNames, customCss]);

    if (this.options.open) {
      Element.show(this.content);
      this.classNames.addClassNames(this.sw, 'open');
    } else {
      Element.hide(this.content);
      this.classNames.addClassNames(this.sw, 'close');
    }
    var switchList = [this.sw].concat(this.options.subSwitch);
    this.setSwitch(switchList);
  },

  setSwitch: function(switchList) {
    switchList = (switchList.constructor == Array) ? switchList : [switchList];
    switchList.each(function(sw) {
      this.classNames.addClassNames(sw, 'sw');
      Event.observe(sw, 'click', this.toggle.bindAsEventListener(this));
    }.bind(this));
  },

  toggle: function(event) {
    if (Element.hasClassName(this.sw, Switcher.classNames.close)) {
      this.open();
    }else {
      this.close();
    }
    Event.stop(event);
  },

  open: function() {
    this.options.beforeOpen(this.content);
    this.classNames.removeClassNames(this.sw, 'close');
    this.classNames.addClassNames(this.sw, 'open');
    if (this.options.effect) {
      new Effect.BlindDown(this.content, {duration: this.options.duration});
    } else {
      Element.show(this.content);
    }
    this.options.afterOpen(this.content);
  },

  close: function() {
    this.options.beforeClose(this.content);
    this.classNames.removeClassNames(this.sw, 'open')
    this.classNames.addClassNames(this.sw, 'close');
    if (this.options.effect) {
      new Effect.BlindUp(this.content, {duration: this.options.duration});
    } else {
      Element.hide(this.content);
    }
    this.options.afterClose(this.content);
  }
}
