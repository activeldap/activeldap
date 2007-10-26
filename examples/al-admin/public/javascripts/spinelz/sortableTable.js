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

var SortableTable = Class.create();

SortableTable.classNames = {
  header: 'sortableTable_header',
  title: 'sortableTable_title',
  empty: 'sortableTable_empty',
  down: 'sortableTable_down',
  up: 'sortableTable_up',
  mark: 'sortableTable_mark',
  thead: 'sortableTable_thead',
  tbody: 'sortableTable_tbody'
}

SortableTable.prototype = {
  
  initialize:  function(element) {
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});

    var options = Object.extend({
      sortType: false,
      cssPrefix: 'custom_'
    }, arguments[1] || {});
    
    var customCss = CssUtil.appendPrefix(options.cssPrefix, SortableTable.classNames);
    this.classNames = new CssUtil([SortableTable.classNames, customCss]);
    
    this.sortType = options.sortType;
    
    this.currentOrder = 'default';
    this.defaultOrder = new Array();
    for (var i = 1; i < this.element.rows.length; i++) {
      this.defaultOrder[i - 1] = this.element.rows[i];
    }
    
    this.build();
    Element.setStyle(this.element, {visibility: 'visible'});
  },
  
  build: function() {
    thead = this.element.tHead;
    this.classNames.addClassNames(thead, 'thead');
    tbody = thead.nextSibling;
    while ((tbody.nodeType != 1) || (tbody.tagName.toLowerCase() != 'tbody')) {
      tbody = tbody.nextSibling;
    }
    this.classNames.addClassNames(tbody, 'tbody');
    var rows = this.element.rows[0];
    if (!rows) return;
    
    for (var i = 0; i < rows.cells.length; i++) {
      
      var cell = rows.cells[i];
      cell.style.cursor = 'pointer';
      
      Element.cleanWhitespace(cell);
      var title = Builder.node('DIV', $A(cell.childNodes));
      this.classNames.addClassNames(title, 'title');
      
      var img = Builder.node('DIV');
      this.classNames.addClassNames(img, 'mark');
      this.classNames.addClassNames(img, 'empty');

      var header = Builder.node('DIV', [title, img]);
      this.classNames.addClassNames(header, 'header');
      cell.appendChild(header);
      
      var titleWidth = title.offsetWidth;
      var imgWidth = img.offsetWidth;
      
      title.style.width = (titleWidth + imgWidth) + 'px';
      Event.observe(rows.cells[i], 'click', this.sortTable.bindAsEventListener(this));
    }
  },

  sortTable: function(event) {
    var cell = Event.element(event);

    if (cell.tagName.toUpperCase() != 'TD' && cell.tagName.toUpperCase() != 'TH') {
      cell = Element.getParentByTagName(['TD','TH'], cell);
    }

    var tmpColumn = cell.cellIndex;
    if (this.targetColumn != tmpColumn) {
      this.currentOrder = 'default';
    }
    this.targetColumn = tmpColumn;
    
    var newRows = new Array();
    for (var i = 1; i < this.element.rows.length; i++) {
      newRows[i - 1] = this.element.rows[i];
    }
    if (newRows.length < 1) return;
        
    if (this.currentOrder == 'default') {
      newRows.sort(this.getSortFunc());
      this.currentOrder = 'asc';
    } else if (this.currentOrder == 'asc') {
      newRows = newRows.reverse();
      this.currentOrder = 'desc';
    } else if (this.currentOrder == 'desc') {
      newRows = this.defaultOrder;
      this.currentOrder = 'default';
    }
    
    for (var i = 0; i < newRows.length; i++) {
      this.element.tBodies[0].appendChild(newRows[i]);
    }
    
    this.mark(cell);
  },
  
  mark: function(cell) {
    var images = document.getElementsByClassName(SortableTable.classNames.mark, this.element);
    var targetImg = document.getElementsByClassName(SortableTable.classNames.mark, cell)[0];
    
    for (var i = 0; i < images.length; i++) {
      var parent = images[i].parentNode;
      var title = document.getElementsByClassName(SortableTable.classNames.title, parent)[0];
      var titleWidth = title.offsetWidth;
      
      if (targetImg == images[i]) {
        
         var imgWidth = targetImg.offsetWidth;
      
        if (this.currentOrder == 'asc') {
          this.classNames.addClassNames(targetImg, 'down');
          this.classNames.removeClassNames(targetImg, 'empty');
          if (!document.all) title.style.width = (titleWidth - imgWidth) + 'px';
          
        } else if (this.currentOrder == 'desc') {
          this.classNames.addClassNames(targetImg, 'up');
          this.classNames.removeClassNames(targetImg, 'down');
        
        } else if (this.currentOrder == 'default') {
          this.classNames.addClassNames(targetImg, 'empty');
          this.classNames.removeClassNames(targetImg, 'up');
          if (!document.all) title.style.width = (titleWidth + imgWidth) + 'px';
        }
        
      } else {
        
        if (Element.hasClassName(images[i], SortableTable.classNames.empty))
          continue;
        
        else if (Element.hasClassName(images[i], SortableTable.classNames.down))
          this.classNames.removeClassNames(images[i], 'down');
        
        else if (Element.hasClassName(images[i], SortableTable.classNames.up))
          this.classNames.removeClassNames(images[i], 'up');
        
         var imgWidth = targetImg.offsetWidth;
        this.classNames.addClassNames(images[i], 'empty');
        if (!document.all) title.style.width = (titleWidth + imgWidth) + 'px';
      }
    }
  },

  getSortFunc: function() {
    if (!this.sortType || !this.sortType[this.targetColumn])
      return SortFunction.string(this);
    
    var type = this.getSortType();
    
    if (!this.sortType || !type) {
      return SortFunction.string(this);
    } else if (type == SortFunction.numeric) {
      return SortFunction.number(this);
    } 
    
    return SortFunction.date(this);
  },
  
  getSortType: function() {
    return this.sortType[this.targetColumn];
  }
}

var SortFunction = Class.create();
SortFunction = {
  string: 'string',
  numeric: 'numeric',
  mmddyyyy: 'mmddyyyy',
  mmddyy: 'mmddyy',
  yyyymmdd: 'yyyymmdd',
  yymmdd: 'yymmdd',
  ddmmyyyy: 'ddmmyyyy',
  ddmmyy: 'ddmmyy',
  
  date: function(grid) {
    return function(fst, snd) {
      var aValue = Element.collectTextNodes(fst.cells[grid.targetColumn]);
      var bValue = Element.collectTextNodes(snd.cells[grid.targetColumn]);
      var date1, date2;
      
      var date1 = SortFunction.getDateString(aValue, grid.getSortType());
      var date2 = SortFunction.getDateString(bValue, grid.getSortType());
      
      if (date1 == date2) return 0;
      if (date1 < date2) return -1;
      
      return 1;
    }
  },
  
  number: function(grid) {
    return function(fst, snd) {
      var aValue = parseFloat(Element.collectTextNodes(fst.cells[grid.targetColumn]));
      if (isNaN(aValue)) aValue = 0;
      var bValue = parseFloat(Element.collectTextNodes(snd.cells[grid.targetColumn])); 
      if (isNaN(bValue)) bValue = 0;
      
      return aValue - bValue;
    }
  },
  
  string: function(grid) {
    return function(fst, snd) {
      var aValue = Element.collectTextNodes(fst.cells[grid.targetColumn]);
      var bValue = Element.collectTextNodes(snd.cells[grid.targetColumn]);
      if (aValue == bValue) return 0;
      if (aValue < bValue) return -1;
      return 1;
    }
  },
  
  getDateString: function(date, type) {
    var array = date.split('/');

    if ((type == SortFunction.mmddyyyy) ||
        (type == SortFunction.mmddyy)) {
      var newArray = new Array();
      newArray.push(array[2]);
      newArray.push(array[0]);
      newArray.push(array[1]);
    } else if ((type == SortFunction.ddmmyyyy) ||
               (type == SortFunction.ddmmyy)) {
      var newArray = new Array();
      newArray.push(array[2]);
      newArray.push(array[1]);
      newArray.push(array[0]);
    } else {
      newArray = array;
    }
    
    return newArray.join();
  }
}

