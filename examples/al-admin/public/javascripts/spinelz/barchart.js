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

var AbstractBarChart = Class.create();
AbstractBarChart.prototype = {

  initialize: function(element, params) {
    this.options = Object.extend({
      title: '',
      graduation: true,
      graduationMin: 0,
      graduationMax: 30,
      graduationInterval: 10, 
      graduationRange: 50,
      titleFont: 'normal bold 20px serif'
    }, arguments[2] || {});
    
    this.fontSize = 'normal normal 12px serif';
    this.graduationLine = '2px solid gray';
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    Element.hide(this.element);
    this.params = params;
    
    this.init();
    
    this.hide();
    this.refresh();
    Element.setStyle(this.element, {visibility: 'visible'});
    Element.show(this.element);
  },
  
  build: function() {
    return Builder.node(
              'DIV',
              [this.buildTitle(), this.buildGraduationLine(), this.buildContent()]);
  },
  
  buildTitle: function() {
    return Builder.node(
              'DIV', 
              {style: 'font: ' + this.options.titleFont + '; margin-bottom: 5px; text-align: center;'},
              [this.options.title]
            );
  },
  
  show: function() {
    Element.show(this.element);
  }, 
  
  hide: function() {
    Element.hide(this.element);
  },
  
  refresh: function(subject) {
    if (this.chart) this.remove();
    
    this.chart = this.build();
    this.element.appendChild(this.chart);
  },
    
  getParam: function(name) {
    return this.params.detect(function(child) {
      return (child.getName() == name);
    });
  },
  
  remove: function() {
    var chart = this.chart;
    var element = this.element;
    
    $A(this.element.childNodes).any(function(child) {
      if (child == chart) {
        element.removeChild(child);
        return true;
      }
      return false;
    });
    
    this.chart = null;
  },
  
  getChartSize: function() {
    return this.getPlusChartSize() + this.getMinusChartSize();
  },
  
  getPlusChartSize: function() {
    if (this.options.graduationMax <= 0) return 0;
    return this.options.graduationMax / this.options.graduationInterval * this.options.graduationRange;
  },
  
  getMinusChartSize: function() {
    if (this.options.graduationMin >= 0) return 0;
    return Math.abs(this.options.graduationMin) / this.options.graduationInterval * this.options.graduationRange;
  },
  
  getBarSize: function(param) {
    var size = param.getValue() / this.options.graduationInterval * this.options.graduationRange;
    return Math.abs(size);
  },
  
  getFontSize: function() {
    var arr = this.fontSize.split(' ');
    if (arr.length == 0) return 0;
    
    var size = arr.detect(function(child) {
      return child.match(/px$/);
    });
    if (!size) return 0;
    
    var index = size.indexOf('px');
    if (index < 1) return 0;
    
    size = size.substring(0, index);
    if (isNaN(size)) return 0;
    
    return parseInt(size);
  }
}

var HorizontalBarChart = Class.create();
Object.extend(Object.extend(HorizontalBarChart.prototype, AbstractBarChart.prototype), {
  
  init: function() {
    this.nameWidth = 125;
    this.valueWidth = 50;
    this.itemInterval = 35;
    this.adjustWidth = (document.all) ? 5 : 0;
  },
  
  buildGraduationLine: function() {
    if (!this.options.graduation)
      return Builder.node('DIV', {style: 'margin-bottom: 5px; text-align: center;'});
    
    var array = new Array();
    var i = this.options.graduationMin;
    //var width = (document.all) ? this.options.graduationRange : this.options.graduationRange - 2;
    var width = this.options.graduationRange;
    
    var style = new StyleManager();
    style.cache('border-left', this.graduationLine);
    style.cache('height', '5px');
    style.cache('font-size', '5px');
    
    while (i <= this.options.graduationMax) {
            
      var j =  i + this.options.graduationInterval;            
      if (j <= this.options.graduationMax)
        style.add('border-top', this.graduationLine);
        
      var elm = Builder.node(
                  'DIV', 
                  {style: 'float: left; font: ' + this.fontSize + '; width: ' + width + 'px;'}, 
                  [
                    Builder.node('DIV', [i]),
                    Builder.node('DIV', {style: style.output()})
                  ]
                );
                
      array.push(elm);
      i = j;
      style.clear();
    }
    return Builder.node('DIV', {style: 'margin-left: ' + (this.nameWidth + this.valueWidth) + 'px; padding-bottom: ' + this.itemInterval + 'px;'}, array);
  },
  
  buildContent: function() {
    var nodes = new Array();
    
    var valueStyle = new StyleManager();
    valueStyle.cache('font', this.fontSize);
    valueStyle.cache('text-align', 'right');
    
    for (var i = 0; i < this.params.length; i++) {
      var child = this.params[i];
      
      var maxSize;
      if (child.getValue() > 0) maxSize = this.getPlusChartSize();
      else maxSize = this.getMinusChartSize();
      
      var barSize = this.getBarSize(child);
      barSize = (barSize > maxSize) ? maxSize : barSize;
      
      var barNode;
      if (child.options.image) {
        if (child.getValue() > 0) {
          
          barNode = Builder.node('DIV', 
                      [
                        Builder.node(
                          'IMG', 
                          {
                            src: child.options.image,
                            alt: 'bar',
                            width: barSize + 'px', 
                            height: child.options.imageHeight + 'px', 
                            style: 'float: left; margin-left: ' +  (this.getMinusChartSize() + this.valueWidth) + 'px;'
                          }),
                        Builder.node(
                          'DIV', 
                          {style: 'font: ' + this.fontSize + ';'}, 
                          [child.getValue()])
                      ]);
        } else {
          // IE fix
          var leftMargin = this.getMinusChartSize() - barSize;
          var width;
          if (document.all && leftMargin > 125) {
            width = leftMargin + this.valueWidth;
            leftMargin = 0;
          } else {
            width = this.valueWidth;
          }
          
          valueStyle.add('margin-left', leftMargin + 'px');
          valueStyle.add('width', width + 'px');
          valueStyle.add('float', 'left');
        
          barNode = Builder.node(
                      'DIV', 
                      [
                        Builder.node('DIV', {style: valueStyle.output()}, [child.getValue()]),
                        Builder.node('IMG', {src: child.options.image, alt: 'bar', width: barSize + 'px', height: child.options.imageHeight + 'px'})
                      ]);
        }
        
      } else {
        if (child.getValue() > 0) {
          barNode = Builder.node(
                      'DIV', 
                      {style: 'font: ' + this.fontSize + '; margin-left: ' + (this.getMinusChartSize() + this.nameWidth + this.valueWidth + this.adjustWidth) + 'px; border-left: ' + barSize + 'px solid ' + child.options.color + ';'},
                      [child.getValue()]
                    );
        } else {
          var width = (document.all) ? (this.valueWidth + barSize) : this.valueWidth;
          
          valueStyle.add('margin-left', (this.nameWidth + this.getMinusChartSize() - barSize) + 'px');
          valueStyle.add('width', width + 'px');
          valueStyle.add('border-right', barSize + 'px solid ' + child.options.color);
          
          barNode = Builder.node(
                      'DIV', 
                      [
                        Builder.node('DIV', {style: valueStyle.output()}, [child.getValue()])
                      ]
                    );
        }
      }
      
      var elm = Builder.node(
                  'DIV', 
                  {style: 'margin-bottom: 10px;'}, 
                  [
                    Builder.node('DIV', {style: 'text-align: right; font: ' + this.fontSize + ';float: left; width: ' + this.nameWidth + 'px;'}, [child.getName()]),
                    barNode
                  ]);
      
      nodes.push(elm);
      valueStyle.clear();
    }
                  
    return nodes;
  }
});

var VerticalBarChart = Class.create();
Object.extend(Object.extend(VerticalBarChart.prototype, AbstractBarChart.prototype), {
  
  init: function() {
  },
  
  buildGraduationLine: function() {
    if (!this.options.graduation) return Builder.node('DIV');
    
    var numberArray = new Array();
    var lineArray = new Array();
    var i = this.options.graduationMax;
    var next;
    var lineHeight = (document.all) ? this.options.graduationRange : this.options.graduationRange - 2;
    var marginTop = lineHeight - this.getFontSize();
    
    var numberStyle = new StyleManager();
    numberStyle.cache('font', this.fontSize);
        
    var lineStyle = new StyleManager();
    lineStyle.cache('font', this.fontSize);
  
    while (i >= this.options.graduationMin) {
      next = i - this.options.graduationInterval;
      lineHeight = (document.all) ? lineHeight - 0.3: lineHeight - 0.1;
      
      if (i == this.options.graduationMax) {
        lineStyle.add('margin-top', '0px');
      
      } else if (next < this.options.graduationMin) {
        numberStyle.add('margin-top', marginTop + 'px');
        lineStyle.add('border-left', this.graduationLine);
        lineStyle.add('border-top', this.graduationLine);
        lineStyle.add('border-bottom', this.graduationLine)
        lineStyle.add('height', lineHeight + 'px');
        lineStyle.add('width', '100%');
      
      } else {
        numberStyle.add('margin-top', marginTop + 'px');
        lineStyle.add('border-left', this.graduationLine);
        lineStyle.add('border-top', this.graduationLine);
        lineStyle.add('height', lineHeight + 'px');
        lineStyle.add('width', '100%');
      }  
      
      numberArray.push(Builder.node('DIV', {style: numberStyle.output()}, [i]));
      
      if (i == this.options.graduationMax) {
        lineArray.push(Builder.node('DIV', {style: lineStyle.output()}, [Builder.node('BR')]));
      } else {
        lineArray.push(Builder.node('DIV', {style: lineStyle.output()}));
      }
      
      numberStyle.clear();
      lineStyle.clear();
      
      marginTop -= (document.all) ? 0.05 : 0.1; 
      i = next;
    }
    
    return [
              Builder.node('DIV', {style: 'float: left; margin-left: 10px; width: 25px; text-align: right;'}, numberArray),
              Builder.node('DIV', {style: 'float: left; margin-right: 10px; margin-left: 10px; width: 5px;'}, lineArray)
            ];
  },
  
  buildContent: function() {
    var nodes = new Array();
    
    for (var i = 0; i < this.params.length; i++) {
      var child = this.params[i];
      
      var maxSize;
      if (child.getValue() > 0) maxSize = this.getPlusChartSize();
      else maxSize = this.getMinusChartSize();
      
      var barSize = this.getBarSize(child);
      barSize = (barSize > maxSize) ? maxSize : barSize;
      
      var bar;
      if (child.options.image) {
        bar = Builder.node('IMG', {src: child.getImage(), alt: 'bar', width: '10px', height: barSize + 'px'});
      } else {
        bar = Builder.node('DIV', {style: 'border-top: ' + barSize + 'px solid ' + child.options.color + '; width: 10px; font-size: 0;'});
      }
      
      var elm;
      if (child.getValue() > 0) {
        elm = Builder.node(
                'DIV', 
                {style: 'float: left; margin-right: 10px; width: 25px;'},
                [
                  Builder.node('DIV', {style: 'margin-top: ' + (maxSize - barSize) + 'px; font: ' + this.fontSize + ';'}, [child.getValue()]),
                  bar,
                  Builder.node('DIV', {style: 'margin-top: ' + (this.getMinusChartSize() + 15) + 'px; font: ' + this.fontSize + '; padding-top: 5px; width: 10px;'}, [child.getName()])
                ]);
      } else {
        elm = Builder.node(
                'DIV', 
                {style: 'float: left; margin-right: 10px; width: 25px;'},
                [
                  Builder.node('DIV', {style: 'margin-top: ' + (this.getPlusChartSize() + this.getFontSize()) + 'px'}),
                  bar,
                  Builder.node('DIV', {style: 'font: ' + this.fontSize + ';'}, [child.getValue()]),
                  Builder.node('DIV', {style: 'margin-top: ' + (maxSize + 15 - (this.getFontSize() + barSize)) + 'px; font: ' + this.fontSize + '; padding-top: 5px; width: 10px;'}, [child.getName()])
                ]);
      }
      
      nodes.push(elm);
    }
                  
    nodes.push(Builder.node('DIV', {style: 'clear: left;'}));
    return nodes;
  }
});

var ChartParameter = Class.create();
ChartParameter.prototype = {

  initialize: function(name, value) {
    if (isNaN(value)) throw '[ChartParameter] value property must be number!(' + value + ')';
    
    this.name = name;
    this.value = value;
    
    this.options = Object.extend({
      color: '#FF0000',
      barHeight: '15',
      image: false,
      imageHeight: '15',
      action: false
    }, arguments[2] || {});
  },
  
  getName: function() {
    return this.name;
  },
  
  getValue: function() {
    return this.value;
  },
  
  setValue: function(value) {
    if (!value || isNaN(value)) this.value = 0;
    else this.value = value;
  },
  
  getImage: function() {
    return this.options.image;
  }
}

var StyleManager = Class.create();
StyleManager.prototype = {
  
  initialize: function() {
    this.cacheItems = new Array();
    this.items = new Array();
  },
  
  cache: function(style) {
    if (typeof(style) == 'object') 
      this.cacheItems.push(style);
    else if (arguments[1])
      this.cacheItems.push(new StyleItem(style, arguments[1]));
  },
  
  add: function(style) {
    if (typeof(style) == 'object') 
      this.items.push(style);
    else if (arguments[1]) 
      this.items.push(new StyleItem(style, arguments[1]));
  },
  
  get: function(name) {
    return this.items.detect(function(child) {
      return child.getName() == name;
    });
  },
  
  remove: function(name) {
    this.items = this.items.findAll(function(child) {
      return child.getName() != name;
    });
  },
  
  clear: function(name) {
    this.items = new Array();
  },
  
  modify: function(name, value) {
    var item = this.get(name);
    
    if (item) item.setValue(value);
    else this.add(name, value);
  },
  
  output: function() {
    var style = '';
    
    this.cacheItems.each(function(child) {
      style += child.toString();
    });
    
    this.items.each(function(child) {
      style += child.toString();
    });
    
    return style;
  }
}

var StyleItem = Class.create();
StyleItem.prototype = {
  
  initialize: function(name, value) {
    this.name = name;
    this.value = value;
  },
  
  setName: function(name) {
    this.name = name;
  },
  
  setValue: function(value) {
    this.value = value;
  },
  
  getName: function() {
    return this.name;
  },
  
  getValue: function() {
    return this.value;
  },
  
  toString: function() {
    return this.getName() + ':' + this.getValue() + '; ';
  }
}

