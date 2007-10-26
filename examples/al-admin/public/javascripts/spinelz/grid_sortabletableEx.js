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


SortableTableGridEx = Class.create();
Object.extend(Object.extend(SortableTableGridEx.prototype, SortableTable.prototype), {

  initialize:  function(element) {
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});

    var options = Object.extend({
      ascImg: false,
      descImg: false,
      handle: false,
      callBack: false
    }, arguments[1] || {});
    this.options = options;
    
    this.handle = options.handle ? $(options.handle) : this.element.rows[0];
    this.ascImg = options.ascImg ? options.ascImg : 'images/spinelz/sortableTable_down.gif';
    this.descImg = options.descImg ? options.descImg : 'images/spinelz/sortableTable_up.gif';
    this.sortType = options.sortType;
    
    this.currentOrder = 'default';
    this.defaultOrder = new Array();
    for (var i = 0; i < this.element.rows.length; i++) {
      this.defaultOrder[i] = this.element.rows[i];
    }    
    this.addEvents();
    Element.setStyle(this.element, {visibility: 'visible'});
  },
  
  addEvents: function() {
    var rows = this.handle.rows[0];
    if (!rows) return;
    
    for (var i = 0; i < rows.cells.length; i++) {
      Element.cleanWhitespace(rows.cells[i]);
      Element.cleanWhitespace(rows.cells[i].firstChild);
      this.addEvent(rows.cells[i].firstChild.firstChild);  
    }
  },
  
  addEvent: function(handle) {
    if (handle) {
      handle.style.cursor = 'pointer';
      Event.observe(handle, 'click', this.sortTable.bindAsEventListener(this));
    }
  },
  
  sortTable: function(event) {
    var target = Event.element(event);
    if (target.tagName.toUpperCase() == 'IMG') {
      target = target.parentNode;
    }
    var cell = target;
    if (cell.tagName.toUpperCase() != 'TD' && cell.tagName.toUpperCase() != 'TH') {
      cell = Element.getParentByTagName(['TD','TH'], cell);
    }
    var tmpColumn = cell.cellIndex;
    if (this.targetColumn != tmpColumn) {
      this.currentOrder = 'default';
    }
    this.targetColumn = tmpColumn;
    
    var newRows = new Array();
    for (var i = 0; i < this.element.rows.length; i++) {
      newRows[i] = this.element.rows[i];
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
    
    this.mark(target);
    if (this.options.callBack) this.options.callBack(this.element); 
  },
  
  mark: function(cell) {
    var row = this.options.handle ? this.options.handle.rows[0] : this.element.rows[0];
    
    var imgs = row.getElementsByTagName('IMG');

    for (var i = 0; i < imgs.length; i++){
      var parent = imgs[i].parentNode;
      parent.removeChild(imgs[i]);
    }
    var imgFile;
    if (this.currentOrder == 'asc') imgFile = this.ascImg;
    else if (this.currentOrder == 'desc') imgFile = this.descImg;
    
    if (imgFile)
      cell.appendChild(Builder.node('IMG', {src: imgFile, alt: 'sortImg'}));
  } 

});

