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

var DatePicker = Class.create();
DatePicker.className = {
  container:     'datepicker',
  header:        'datepicker_header',
  footer:        'datepicker_footer',
  preYears:      'datepicker_preYears',
  nextYears:     'datepicker_nextYears',
  years:         'datepicker_years',
  calendar:      'datepicker_calendar',
  date:          'datepicker_date',
  holiday:       'datepicker_holiday',
  ym:            'datepicker_ym',
  table:         'datepicker_table',
  tableTh:       'datepicker_tableTh',
  nextMonthMark: 'datepicker_nextMonthMark',
  nextYearMark:  'datepicker_nextYearMark',
  preMonthMark:  'datepicker_preMonthMark',
  preYearMark:   'datepicker_preYearMark',
  today:         'datepicker_today',
  zIndex:        null
}
DatePicker.prototype = {
  
  initialize: function(element, target, trigger) {
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    this.target = $(target);

    this.options = Object.extend({
      date:         new Date(),
      format:       DateUtil.toLocaleDateString,
      cssPrefix:    'custom_',
      callBack:     Prototype.emptyFunction,
      standBy:      false,
      headerFormat: null,
      dayOfWeek:    DateUtil.dayOfWeek,
      appendToBody: false,
      invalidDates: []
    }, arguments[3] || {});
    
    this.css = CssUtil.getInstance(this.options.cssPrefix, DatePicker.className);
    this.classNames = this.css.allJoinClassNames();
    
    this.format = this.options.format;
    this.callBack = Prototype.emptyFunction;

    if (this.options.date) {
      if (this.options.date.constructor == Date) {
        this.date = this.options.date;
      } else {
        this.date = DateUtil.toDate(this.options.date);
      }
    } else {
      this.date = new Date();
    }
    this.originalDate = new Date(this.date.getTime());
    
    this.ids = {};
    this.dateIds = [];
    this.element.innerHTML = this.build();
    this.cover = new IECover(this.element);
    this.setEvent();
    
    this.doclistener = this.hide.bindAsEventListener(this);
    this.hide();
    Element.setStyle(this.element, {visibility: 'visible'});
    this.triggerSet = {};
    if (trigger && target) this.set(trigger, target, this.options.callBack);
    if (this.options.appendToBody) Element.appendToBody.callAfterLoading(this, this.element);
  },

  set: function(trigger, target, options) {
    trigger = $(trigger);
    options = options || {};
    if (options.constructor == Function) options = {callBack: options}
    options = $H({
      callBack:     Prototype.emptyFunction,
      invalidDates: []
    }).merge(options);
    if (options.invalidDates.constructor != Array) options.invalidDates = [options.invalidDates];

    this.triggerSet[trigger.id] = {target: $(target), options: options};
    this.addTrigger(trigger);
  },

  setEvent: function() {
    var preMonth = $(this.ids.preMonth)
    if (!Event.observers || !Event.observers.any(function(observer) { return preMonth == observer.first(); })) {
      Event.observe(this.ids.preMonth, "click", this.changeCalendar.bindAsEventListener(this));
      Event.observe(this.ids.preYear, "click", this.changeCalendar.bindAsEventListener(this));
      Event.observe(this.ids.nextMonth, "click", this.changeCalendar.bindAsEventListener(this));
      Event.observe(this.ids.nextYear, "click", this.changeCalendar.bindAsEventListener(this));
      new Hover(this.ids.preMonth);
      new Hover(this.ids.preYear);
      new Hover(this.ids.nextMonth);
      new Hover(this.ids.nextYear);

      this.hovers = {};
      this.dateIds.each(function(id) {
        this.hovers[id] = new Hover(id, {beforeToggle: this.hasDate.bind(this, id)});
        Event.observe(id, "click", this.selectDate.bindAsEventListener(this));
      }.bind(this));
    }
  },
  
  build: function() {
    this.ids.calendar = this.element.id.appendSuffix('calendar');
    var html = 
      "<div id='" + this.ids.calendar + "' class='" + this.classNames['container'] + "'>" +
        this.buildHeader() +
        this.buildCalendar() +
        this.buildFooter() +
      "</div>";
    return html;
  },
  
  buildHeader: function() {
    var html =
      "<table class='" + this.classNames['header'] + "'>" +
        "<tr>" +
          this.buildHeaderLeft() +
          this.buildHeaderCenter() +
          this.buildHeaderRight() +
        "</tr>" +
      "</table>";
    return html;
  },

  buildFooter: function() {
    return "<div class='" + this.classNames['footer'] + "'></div>";
  },

  buildHeaderLeft: function() {
    this.ids.preYear = this.element.id.appendSuffix('preYear');
    this.ids.preMonth = this.element.id.appendSuffix('preMonth');

    var html =
      "<td class='" + this.classNames['preYears'] + "'>" +
        "<div id='" + this.ids.preYear + "' class='" + this.classNames['preYearMark'] + "'></div>" +
        "<div id='" + this.ids.preMonth + "' class='" + this.classNames['preMonthMark'] + "'></div>" +
      "</td>";
    return html;
  },

  buildHeaderCenter: function() {
    var yearMonth = this.getHeaderYearMonth();
    var baseId = this.element.id;
    var html =
      "<td class='" + this.classNames['years'] + "'>" +
        "<span id='" + baseId.appendSuffix('ym0') + "'class='" + this.classNames['ym'] + "'>" +
          yearMonth[0] +
        "</span>" +
        "<span id='" + baseId.appendSuffix('ym1') + "' class='" + this.classNames['ym'] + "'>" +
          yearMonth[1] +
        "</span>" +
      "</td>";
    return html;
  },

  getHeaderYearMonth: function() {
    if (this.options.headerFormat) {
      var tmpl = new Template(this.options.headerFormat);
      return [tmpl.evaluate({year: this.date.getFullYear(), month: this.date.getMonth() + 1}), ' '];
    }
    return [DateUtil.months[this.date.getMonth()], this.date.getFullYear()];
  },

  buildHeaderRight: function() {
    this.ids.nextYear = this.element.id.appendSuffix('nextYear');
    this.ids.nextMonth = this.element.id.appendSuffix('nextMonth');

    var html =
      "<td class='" + this.classNames['nextYears'] + "'>" +
        "<div id='" + this.ids.nextMonth + "' class='" + this.classNames['nextMonthMark'] + "'></div>" +
        "<div id='" + this.ids.nextYear + "' class='" + this.classNames['nextYearMark'] + "'></div>" +
      "</td>";
    return html;
  },
  
  multiBuild: function(tagType, params, className, hover, clickEvent) {
    var children = [];
    for (var i = 0; i < params.length; i++) {
      var node = Builder.node(tagType, [params[i]]);;
      if (className)
        this.classNames.addClassNames(node, className);
      if (hover)
        new Hover(node);
      if (clickEvent)
        Event.observe(node, "click", clickEvent.bindAsEventListener(this));
      children.push(node);
    }
    return children;
  },
  
  buildCalendar: function() {
    var html = 
      "<div class='" + this.classNames['calendar'] + "'>" +
        "<table class='" + this.classNames['table'] + "'>" +
          this.buildTableHeader() + this.buildTableData() +
        "</table>" +
      "</div>";
    return html;
  },
  
  buildTableHeader: function() {
    var className = this.classNames['tableTh'];
    var html = "<tr>";
    for (var i = 0; i < DateUtil.dayOfWeek.length; i++) {
      html += "<th class='" + className + "'>" + this.options.dayOfWeek[i] + "</th>";
    }
    html += "</tr>";
    return html;
  },
  
  buildTableData: function() {
    var length = DateUtil.dayOfWeek.length * 6;
    var year = this.date.getFullYear();
    var month = this.date.getMonth();
    var firstDay = DateUtil.getFirstDate(year, month).getDay();
    var lastDate = DateUtil.getLastDate(year, month).getDate();
    var tdBaseId = this.element.id.appendSuffix('date');
    var today = new Date();
    var sameMonth = today.sameMonth(this.date);
    var trs = '';
    var tds = '';

    for (var i = 0, day = 1; i < length; i++) {
      var id = tdBaseId.appendSuffix(i);
      this.dateIds.push(id);
      var classKey = ((i % 7 == 0) || ((i+1) % 7 == 0)) ? 'holiday' : 'date';
      var className = this.classNames[classKey];
      if ((i < firstDay) || day > lastDate) {
        tds += "<td id='" + id + "' class='" + className + "'></td>";
      } else {
        if (sameMonth && (today.getDate() == day)) {
          className = this.classNames['today'] + ' ' + className;
          this.todayCell = id;
        }
        tds += "<td id='" + id + "' class='" + className + "'>" + day + "</td>";
        day++;
      }
      
      if ((i + 1) % 7 == 0) {
        trs += "<tr>" + tds + "</tr>";
        tds = '';
      }
    }
    return trs;
  },

  rebuildHeaderCenter: function() {
    var yearMonth = this.getHeaderYearMonth();
    var baseId = this.element.id;
    $(baseId.appendSuffix('ym0')).innerHTML = yearMonth[0];
    $(baseId.appendSuffix('ym1')).innerHTML = yearMonth[1];
  },
  
  rebuildTableData: function() {
    var length = DateUtil.dayOfWeek.length * 6;
    var year = this.date.getFullYear();
    var month = this.date.getMonth();
    var firstDay = DateUtil.getFirstDate(year, month).getDay();
    var lastDate = DateUtil.getLastDate(year, month).getDate();
    var tdBaseId = this.element.id.appendSuffix('date');
    var today = new Date();
    var sameMonth = today.sameMonth(this.date);

    this.todayClassToNormalClass();
    for (var i = 0, day = 1; i < length; i++) {
      var id = tdBaseId.appendSuffix(i);
      var element = $(id);
      if ((i < firstDay) || (day > lastDate)) {
        element.innerHTML = '';
      } else {
        element.innerHTML = day;
        if (sameMonth && (today.getDate() == day)) {
          element.className = this.classNames['today'] + ' ' + element.className;
          this.todayCell = id;
          this.hovers[id].refresh();
        }
        day++;
      }
    }
  },

  todayClassToNormalClass: function() {
    var todayClassName = this.classNames['today'].split(' ');
    var cell = $(this.todayCell);
    if (cell) {
      cell.className = cell.className.split(' ').select(function(className) {
        return !todayClassName.include(className);
      }).join(' ');
      this.hovers[this.todayCell].refresh();
    }
    this.todayCell = null;
  },
  
  refresh: function() {
    this.rebuildHeaderCenter();
    this.rebuildTableData();
  },
  
  getMonth: function() {
    return  DateUtil.months[this.date.getMonth()];
  },
  
  changeCalendar: function(event) {
    var element = Event.element(event);
    this.date.setDate(1);
    if (this.hasClassName(element, DatePicker.className.preYearMark)) {
      this.date.setFullYear(this.date.getFullYear() - 1);
    } else if (this.hasClassName(element, DatePicker.className.nextYearMark)) {
      this.date.setFullYear(this.date.getFullYear() + 1);
    } else if (this.hasClassName(element, DatePicker.className.preMonthMark)) {
      this.date.setMonth(this.date.getMonth() - 1);
    } else if (this.hasClassName(element, DatePicker.className.nextMonthMark)) {
      this.date.setMonth(this.date.getMonth() + 1);
    }
    
    this.refresh();
    if (event) Event.stop(event);
  },

  hasClassName: function(element, className) {
    return Element.hasClassName(element, className) || Element.hasClassName(element, className + 'Hover')
  },
  
  selectDate: function(event) {
    var src = Event.element(event);
    var text = Element.getTextNodes(src)[0];
    if (text) {
      this.date.setDate(text.nodeValue);
      var value = this.formatDateString();
      
      if (this.target.value || this.target.value == '') {
        this.target.value = value;
      } else {
        this.target.innerHTML = value;
      }
      
      this.hide();
      this.css.refreshClassNames(src, 'date');
      this.callBack(this);
    }
  },
  
  show: function(event) {
    if (event) {
      Event.stop(event);
      var set = this.triggerSet[Event.element(event).id];
      if (set) {
        this.target = set.target;
        this.options = $H(this.options).merge(set.options);
        this.callBack = this.options.callBack;
      }

      if (this.options.invalidDates.include(this.target.value)) {
        this.date = new Date(this.originalDate.getTime());
      } else {
        var time = Date.parse(this.target.value);
        if (time) {
          this.date = new Date(time);
        } else {
          this.date = new Date(this.originalDate.getTime());
        }
      }
      this.refresh();
    }

    var styles = $H({zIndex: ZindexManager.getIndex(this.options.zIndex)});
    if (this.options.standBy) {
      this.defaultParent = this.element.parentNode;
      document.body.appendChild(this.element);
      styles = styles.merge({ 
        position: 'absolute',
        left:     Event.pointerX(event) + 'px',
        top:      Event.pointerY(event) + 'px'
      });
    }

    Element.setStyle(this.element, styles);
    Element.show(this.element);
    this.cover.resetSize();
    Event.observe(document, "click", this.doclistener);
  },
  
  hide: function() {
    Event.stopObserving(document, "click", this.doclistener);
    Element.hide(this.element);
    if (this.defaultParent) {
      this.defaultParent.appendChild(this.element);
    }
  },
  
  addTrigger: function(trigger) {
    Event.observe($(trigger), 'click', this.show.bindAsEventListener(this));
  },
  
  changeTarget: function(target) {
    this.target = $(target);
  },

  formatDateString: function() {
    var string = '';
    if (this.format.constructor == Function) {
      string = this.format(this.date);
    } else if (this.format.constructor == String) {
      string = this.date.strftime(this.format);
    }
    return string;
  },

  hasDate: function(cell) {
    var text = $(cell).innerHTML;
    return text && (text != '');
  }
}
