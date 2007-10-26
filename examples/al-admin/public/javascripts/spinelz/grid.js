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

Grid = Class.create();
Grid.className = {
  container:      'grid_container',
  
  baseTable:      'grid_baseTable',
  baseRow:        'grid_baseRow',
  baseCell:       'grid_baseCell',
  
  headerTable:    'grid_headerTable',
  headerRow:      'grid_headerRow',
  headerCell:     'grid_headerCell',
  headerCellDrag: 'grid_headerCellDrag',
  headerCellSort: 'grid_headerCellVal',
  
  idTable:        'grid_idTable',
  idRow:          'grid_idRow',
  idCell:         'grid_idCell',
  idCellVal:      'grid_idCellVal',
  
  cellTable:      'grid_cellTable',
  cellTbody:      'grid_cellTbody',
  cellRow:        'grid_cellRow',
  cell:           'grid_cell',
  cellVal:        'grid_cellVal',
  cellSelected:   'grid_cellSelected',
  state:          'grid_state',
  stateEmpty:     'grid_stateEmpty',
  stateOpen:      'grid_stateOpen',
  stateClose:     'grid_stateClose',
  
  inplaceEditor:  'grid_inplaceEditor'
}
Grid.scrollTop = 0;
Grid.scrollLeft = 0;
Grid.options = {}
Grid.options.baseTable = {
  border:1,
  frame : 'border',
  cellSpacing:0,
  cellPadding:0
}
Grid.options.headerTable = {
  border:1,
  frame : 'border',
  cellSpacing:0,
  cellPadding:0
}
Grid.options.idTable = {
  border:1,
  frame : 'border',
  cellSpacing:0,
  cellPadding:0
}
Grid.options.cellTable = {
  border:1,
  frame : 'border',
  cellSpacing:0,
  cellPadding:0
}
Grid.prototype = {
  
  initialize : function(element) {
    
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    Element.hide(this.element);

    var options = Object.extend({
      cssPrefix:          'custum_',
      cellMinWidth:       10,
      cellMinHeight:      10,
      cellDefaultWidth:   72,
      cellDefaultHeight:  25,
      defaultRowLength:   10,
      baseWidth:          40,
      baseHeight:         25,
      baseTop:            0,
      baseLeft:           0,
      cellEditUrl:        '',
      updateGridUrl:      '',
      updateGridReceiver: '',
      hierarchy:          false,
      hierarchyCol:       false,
      hierarchyIndent:    20,
      sortOptions:        {}
    }, arguments[1] || {});
    
    this.options = options;
    this.custumCss = CssUtil.appendPrefix(options.cssPrefix, Grid.className);
    this.cssUtil = new CssUtil([Grid.className, this.custumCss]);
    this.cssUtil.addClassNames(this.element, 'container');
    this.hierarchyCol = this.options.hierarchyCol ? $(this.options.hierarchyCol) : false;
    this.hierarchyColIndex = this.hierarchyCol ? this.hierarchyCol.cellIndex : 0;
    Element.makePositioned(this.element);
    Position.includeScrollOffsets = true;
    this.stateDivWidth = parseInt(CssUtil.getCssRuleBySelectorText('.' + Grid.className.state).style.width, 10);
    
    this.marginSize = this.options.marginSize ? this.options.marginSize : 4;
    this.stateIndent = 15;
    
    this.rowIdBase = this.element.id + '_row_';
    this.topLevelList = new Array();
    this.removeList = new Array();
    this.build();
    this.removeList.each(function(r) {
      r.parentNode.removeChild(r);
    });
    var sortOptions = {
      relate : this.idTable,
      handle:this.headerTable,
      callBack:this.finishSort.bind(this)
    };
    sortOptions = $H(sortOptions).merge(this.options.sortOptions);
    this.sortTable = new SortableTableGridEx(this.cellTable, sortOptions);
    Element.setStyle(this.element, {visibility: 'visible'});
    Element.show(this.element);
  },
  
  build: function() {    
    Element.cleanWhitespace(this.element);
    this.cellTable = this.element.childNodes[0];
    Element.cleanWhitespace(this.cellTable);
    
    this.colLength = this.cellTable.tHead.rows[0].cells.length;
    this.rowLength = this.cellTable.tBodies[0].rows.length;
    if (this.rowLength == 0)this.rowLength = this.options.defaultRowLength;
    this.buildBaseTable();
    this.buildHeaderTable();
    this.buildIdTable();
    this.buildCellTable();
    
    Event.observe(this.element, 'scroll', this.fixTablePosition.bindAsEventListener(this));
  },
  
  buildBaseTable: function() {

    this.baseTable = Builder.node('table', Grid.options.baseTable);
    this.cssUtil.addClassNames(this.baseTable, 'baseTable');
    with (this.baseTable.style) {
      width    = this.options.baseWidth + 'px';
      height   = this.options.baseHeight + 'px';
      position = 'absolute';
      top      = this.options.baseTop + 'px';
      left     = this.options.baseLeft + 'px';
    }
    
    var row = this.baseTable.insertRow(0);
    var cell = row.insertCell(0);
    
    this.cssUtil.addClassNames(row, 'baseRow');
    this.cssUtil.addClassNames(cell, 'baseCell');
    
    this.element.appendChild(this.baseTable);
  },
  
  buildHeaderTable: function() {
    this.headerTable = Builder.node('table', Grid.options.headerTable);
    this.cssUtil.addClassNames(this.headerTable, 'headerTable');
    
    var thead = this.cellTable.tHead;
    var row = thead.rows[0];
    row.id = this.element.id + '_headerTable_row';
    var cells = row.cells;
    Element.cleanWhitespace(thead);
    Element.cleanWhitespace(row);
    
    this.cssUtil.addClassNames(row, 'headerRow');
    for (var i = 0; i < cells.length; i++) {
      var cell = cells[i];
      var value = cell.firstChild;
      var title = cell.innerHTML;
      this.buildHeaderCell(cell, title, i);
      this.removeList.push(value);
    }
    this.headerTable.appendChild(thead);
    with (this.headerTable.style) {
      width   = this.options.cellDefaultWidth * this.colLength + 'px';
      height  = this.baseTable.style.height;
      position= 'absolute';
      top     = Element.getStyle(this.baseTable, 'top');
      left    = parseInt(Element.getStyle(this.baseTable, 'left')) + parseInt(Element.getStyle(this.baseTable, 'width')) + 'px';
    }
    this.element.appendChild(this.headerTable);
    Sortable.create(
      row, 
      {
        tag:'td',
        handle:Grid.className.headerCellDrag,
        constraint:true,
        overlap:'horizontal',
        scroll:this.element,
        onUpdate:this.updateCellLine.bind(this)
      });
  },
  
  buildHeaderCell : function(cell, title, index) {

    cell.id = this.element.id + '_header_col_' + index;
    
    var drag = Builder.node('div');
    var sort = Builder.node('div');
    
    this.cssUtil.addClassNames(cell, 'headerCell');
    this.cssUtil.addClassNames(drag, 'headerCellDrag');
    this.cssUtil.addClassNames(sort, 'headerCellSort');
    
    cell.style.width = this.options.cellDefaultWidth + 'px';
    var dragWidth = parseInt(Element.getStyle(cell, 'width')) - (this.marginSize * 2);
    var sortWidth = dragWidth - (this.marginSize * 2);
    var cellHeight = this.options.baseHeight - (Grid.options.headerTable.border * 4);
    with (drag.style) {
      width = dragWidth + 'px';
      height = cellHeight + 'px';
      marginLeft = this.marginSize + 'px';
      marginRight = this.marginSize + 'px';
    }
    with (sort.style) {
      width = sortWidth + 'px';
      height = cellHeight + 'px';
      marginLeft = this.marginSize + 'px';
      marginRight = this.marginSize + 'px';
    }
    
    sort.innerHTML = title;
    drag.appendChild(sort);
    cell.appendChild(drag);
    
    new ResizeableGridEx(cell, {minWidth: this.options.cellMinWidth, top:0,right:2, bottom:0, left:0 ,draw:this.updateCellWidth.bind(this)});
    Event.observe(cell, 'mousedown', this.setSelectedColumn.bindAsEventListener(this));
    Event.observe(drag, 'mousedown', this.setSelectedColumn.bindAsEventListener(this));
    Event.observe(sort, 'mousedown', this.setSelectedColumn.bindAsEventListener(this));  
  },
    
  buildIdTable: function() {

    this.idTable = Builder.node('table', Grid.options.idTable);
    this.cssUtil.addClassNames(this.idTable, 'idTable');
    for (var i = 0; i < this.rowLength; i++) {
      
      var row = this.idTable.insertRow(i);
      this.buildIdRow(row, i);
    }
    
    with(this.idTable.style) {
      width    = this.options.baseWidth + 'px';
      position = 'absolute';
      top      = parseInt(Element.getStyle(this.baseTable, 'top')) + parseInt(Element.getStyle(this.baseTable, 'height')) + 'px';
      left     = Element.getStyle(this.baseTable, 'left');
    }
    
    this.element.appendChild(this.idTable);
    var tbody = this.idTable.tBodies[0];
    tbody.id = this.element.id + '_idTable_tbody';
    Sortable.create(
      tbody, 
      {
        tag:'tr',
        handle:Grid.className.idCellVal,
        scroll:this.element,
        constraint:true,
        overlap:'vertical',
        onUpdate:this.updateRowLine.bind(this)
      });
  },
  
  buildIdRow : function(row, index) {
    row.id = this.rowIdBase + '_id_' + index;
    
    var cell = row.insertCell(0);
    var valueDiv = Builder.node('div');

    this.cssUtil.addClassNames(row, 'idRow');
    this.cssUtil.addClassNames(cell, 'idCell');
    this.cssUtil.addClassNames(valueDiv, 'idCellVal');      
    
    with (cell.style) {
      width = this.options.baseWidth + 'px';
      height = this.options.cellDefaultHeight + 'px';
    }
    with (valueDiv.style) {
      marginTop = this.marginSize + 'px';
      marginBottom = this.marginSize + 'px';
      width = this.options.baseWidth - (Grid.options.idTable.border * 4) + 'px';
      height = this.options.cellDefaultHeight - (this.marginSize * 2) + 'px';
    }

    valueDiv.innerHTML = index + 1;
    cell.appendChild(valueDiv);
    
    new ResizeableGridEx(cell, {minHeight: this.options.cellMinHeight, top:0, right: 0, bottom: 2, left: 0, draw:this.updateCellHeight.bind(this)});
    
    Event.observe(row, 'mousedown', this.setSelectedRow.bindAsEventListener(this));
    Event.observe(cell, 'mousedown', this.setSelectedRow.bindAsEventListener(this));
    Event.observe(valueDiv, 'mousedown', this.setSelectedRow.bindAsEventListener(this));    
  },
  
  buildCellTable: function() {
    var tbody = this.cellTable.tBodies[0];
    Element.cleanWhitespace(tbody);
    with(this.cellTable){
      border = Grid.options.cellTable.border;
      cellSpacing = Grid.options.cellTable.cellSpacing;
      cellPadding = Grid.options.cellTable.cellPadding;
    }
    this.cssUtil.addClassNames(this.cellTable, 'cellTable');
    this.cssUtil.addClassNames(tbody, 'cellTbody');
    this.element.appendChild(this.cellTable);
    var rows = this.cellTable.rows;
    
    if (!rows || rows.length == 0) {
      for(var i = 0; i < this.rowLength; i++) {
        
        var newRow = this.cellTable.insertRow(i);
        newRow.id = this.rowIdBase + i;
        this.cssUtil.addClassNames(newRow, 'cellRow');
        
        for (var j = 0; j < this.colLength; j++) {
          var newCell = newRow.insertCell(j);
          this.buildCell(newCell, j, "");
        }
        if (this.options.hierarchy) {
          this.setHierarchyRow(newRow);
        }
      }  
      
    } else {
      for (var i = 0; i < this.rowLength; i++) {
        var row = rows[i];
        Element.cleanWhitespace(row);
        this.cssUtil.addClassNames(row, 'cellRow');
        row.id = this.rowIdBase + i;
        var cells = row.cells;

        for (var j = 0; j < cells.length; j++) {
          var cell = cells[j];
          Element.cleanWhitespace(cell);
          this.buildCell(cell, j, Element.collectTextNodes(cell));
          this.removeList.push(cell.firstChild);
        }
        if (this.options.hierarchy) {
          this.setHierarchyRow(row);
        }  
      }
    }
    
    with (this.cellTable.style) {
      width   = this.options.cellDefaultWidth * this.colLength + 'px';
      position = 'absolute';
      top      = parseInt(Element.getStyle(this.baseTable, 'top')) + parseInt(Element.getStyle(this.baseTable, 'height')) + 'px';
      left     = parseInt(Element.getStyle(this.baseTable, 'left')) + parseInt(Element.getStyle(this.baseTable, 'width')) + 'px';
    }
    
    this.cellTable.getIdRow = this.getIdRow.bind(this);    
  },

  buildCell : function(cell, cellIdIndex, value) {

    var cellValueDiv = Builder.node('div');
    cellValueDiv.innerHTML = value;
    
    cell.appendChild(cellValueDiv);
    cell.id = cell.parentNode.id + '_col_' + cellIdIndex;
    
    this.cssUtil.addClassNames(cell, 'cell');
    this.cssUtil.addClassNames(cellValueDiv, 'cellVal');
    
    with (cell.style) {
      width = Element.getStyle(this.getHeaderCell(cell), 'width');
      height = Element.getStyle(this.getIdRow(cell.parentNode).cells[0], 'height');
    }  
    with (cellValueDiv.style) {
      width = cell.style.width;
      height = cell.style.height;
      marginTop = '0px';
      marginBottom = '0px';
    }
    
    Event.observe(cell, 'click', this.setSelectedCell.bindAsEventListener(this));
        
    var ajax = new Ajax.InPlaceEditor(cellValueDiv, this.options.cellEditUrl,
      {
        formClassName: this.cssUtil.joinClassNames('inplaceEditor'), 
        rows: 2, 
        cols:12, 
        okButton: false, 
        cancelLink:false, 
        submitOnBlur:true, 
        hoverClassName: "cellHover",
        highlightcolor: "#becfeb",
        highlightendcolor: "#becfeb",
        onComplete: this.showStateDiv.bind(this),
        callback : this.createInplaceEditorParams.bind(this),
        formId : cell.id + '_form'
      }
    );
    cellValueDiv.ajax = ajax;
    Event.stopObserving(cellValueDiv, 'click', ajax.onclickListener);
    Event.stopObserving(cellValueDiv, 'mouseover', ajax.mouseoverListener);
    Event.stopObserving(cellValueDiv, 'mouseout', ajax.mouseoutListener);
    

    Event.observe(cellValueDiv, 'dblclick', this.setTextAreaSize.bindAsEventListener(this));
    if (this.options.hierarchy && cell.cellIndex == this.hierarchyColIndex) {
      Event.observe(cellValueDiv, 'dblclick', this.hideStateDiv.bindAsEventListener(this));
    }
    Event.observe(cellValueDiv, 'dblclick', ajax.onclickListener);
    
  },
  
  addColumn: function(index, colTitle, values) {
    var headerRow = this.headerTable.rows[0];
    var insertIndex = (!isNaN(index)) ? index : this.colLength;
    var colIdIndex = this.colLength;
    var headerCell = headerRow.insertCell(insertIndex);
    this.buildHeaderCell(headerCell, colTitle, insertIndex);
    
    var rows = this.cellTable.rows;
    var idRows = this.idTable.rows;
    for (var i = 0; i < rows.length; i++) {
      
      var cell = rows[i].insertCell(insertIndex);
      var cellValue = "";
      if (values && values[i]) {
        cellValue = values[i];
      }
      this.buildCell(cell, colIdIndex, cellValue);
    }
  
    this.headerTable.style.width = parseInt(Element.getStyle(this.headerTable, 'width')) + this.options.cellDefaultWidth + 'px';
    this.cellTable.style.width = this.headerTable.style.width;
    
    var sortableOptions = Sortable.options(headerRow);
    
    sortableOptions.draggables.push(
      new Draggable(
        headerCell, 
        {
          revert:     true,
          constraint: true,
          scroll:     this.element,
          handle:     Element.getElementsByClassName(headerCell, Grid.className.headerCellDrag)[0]
        }
      )
    );
    Droppables.add(headerCell, {overlap:'horizontal', containment:headerRow, onHover:Sortable.onHover, greedy:true});
    sortableOptions.droppables.push(headerCell);   
    this.sortTable.addEvent(Element.getElementsByClassName(headerCell, Grid.className.headerCellSort)[0]);
    this.colLength += 1;
  },
  
  deleteColumn : function(index) {
    if((isNaN(index)) || index >= this.colLength) {
      return;
    }
    var headerRow = this.headerTable.rows[0];
    if (!headerRow) return;
    var headerCell = headerRow.cells[index];
    if (!headerCell) return;
    
    var width = headerCell.offsetWidth;
    var rows = this.cellTable.rows;
    headerRow.deleteCell(index);
    
    for (var i = 0; i < rows.length; i++) {
      rows[i].deleteCell(index);
    }
    
    var headerTableWidth = parseInt(Element.getStyle(this.headerTable, 'width')) - width;
    
    this.headerTable.style.width = headerTableWidth >= 0 ? headerTableWidth + 'px' : '0px';
    this.cellTable.style.width = this.headerTable.style.width;
    this.colLength -= 1;
    this.fixTablePosition();
  },
  
  addRow : function(index, values) {
    var insertIndex = (!isNaN(index)) ? index : this.idTable.rows.length;
    var rowIdIndex = this.idTable.rows.length;
    var idRow = this.idTable.insertRow(index);
    idRow.id = this.rowIdBase + '_id_' + rowIdIndex;
    this.buildIdRow(idRow, rowIdIndex);
    this.updateId();
    
    var cellRow = this.cellTable.insertRow(insertIndex);
    cellRow.id = this.rowIdBase + rowIdIndex;
    this.cssUtil.addClassNames(cellRow, 'cellRow');
    var headerCells = this.headerTable.rows[0].cells;
    
    for (var i = 0; i < headerCells.length; i++) {
      var headerCell = headerCells[i];
      var colIdIndex = headerCell.id.substring(headerCell.id.indexOf('_col_',0) + '_col_'.length);
      var cell = cellRow.insertCell(i);
      var cellValue = (values && values[i]) ? values[i] : "";
      this.buildCell(cell, colIdIndex, cellValue);
    }

    this.sortTable.defaultOrder.insert(index, cellRow);
    
    var idTbody = this.idTable.tBodies[0];
    var sortableOptions = Sortable.options(idTbody);
    
    sortableOptions.draggables.push(
      new Draggable(
        idRow,
        {
          revert:     true,
          constraint: true,
          scroll:     this.element,
          handle:     Element.getElementsByClassName(idRow, Grid.className.idCellVal)[0]
        }
      )
    );
    Droppables.add(idRow, {overlap:'vertical', containment:idTbody, onHover:Sortable.onHover, greedy:true});
    sortableOptions.droppables.push(idRow);   
    this.rowLength += 1;
    return cellRow;
  },
  
  deleteRow : function(index) {
    if(isNaN(index) || index >= this.rowLength) {
      return;
    }
    
    var targetId = null;
    if (this.cellTable.rows[index])
      targetId = this.cellTable.rows[index].id;
    else
      return;
    
    this.sortTable.defaultOrder.reverse();
    var newOrder = new Array();
    
    for (var i = 0; this.sortTable.defaultOrder.length > 0; i++) {
       var row = this.sortTable.defaultOrder.pop();
       if (row.id == targetId) {
         continue;
       }
       newOrder.push(row);
    }
    
    this.sortTable.defaultOrder = newOrder;
    this.idTable.deleteRow(index);
    this.cellTable.deleteRow(index);
    
    this.fixTablePosition();
    this.rowLength -= 1;
    this.updateId();
  },
  
  getHeaderCell : function(cell) {
    return this.headerTable.rows[0].cells[cell.cellIndex];
  },
  
  getCells : function(index) {
    var rows = this.cellTable.rows;
    var columns = new Array();
    for (var i = 0; i < rows.length; i++){
      columns.push(rows[i].cells[index]);
    }
    return columns;
  },
  
  getRow : function(index) {
    return this.cellTable.rows[index];
  },
  
  getIdRow : function(cellRow) {
    var id = cellRow.id;
    var index = id.substring(this.rowIdBase.length);
    var targetRow = $(this.rowIdBase + '_id_' + index);
    return targetRow;
  },
  
  getColTitle : function(index) {
    var headerCell = this.headerTable.rows[0].cells[index];
    var title = Element.collectTextNodes(headerCell);
    return title;
  },
  
  finishSort : function() {
    for (var i = 0; i < this.cellTable.rows.length; i++) {
      this.idTable.tBodies[0].appendChild(this.getIdRow(this.cellTable.rows[i]));
    }
    this.updateId();
  },
  
  setSelectedCell : function(event) {
    this.removeSelectedClasses();
    var src = Event.element(event);

    if (src.tagName.toUpperCase() != 'TH' && src.tagName.toUpperCase() != 'TD') { 
      src = Element.getParentByTagName(['TH,TD'], src);
    }        
    
    this.targetCell = src;
    
    if (this.targetCell) {
      this.targetColIndex = this.targetCell.cellIndex;
      this.targetRowIndex = this.targetCell.parentNode.rowIndex;
      this.targetColumn = this.getCells(this.targetColIndex);
      this.targetRow = this.getRow(this.targetRowIndex);
    }
    
    this.cssUtil.addClassNames(this.targetCell, 'cellSelected');
    var childNodes = Element.getTagNodes(this.targetCell, true);      
    for (var i = 0; i < childNodes.length; i++) {
      this.cssUtil.addClassNames(childNodes[i], 'cellSelected');
    }
  },
    
  setSelectedColumn : function(event) {
    this.removeSelectedClasses();
    
    this.targetCell = null;
    this.targetRowIndex = null;
    this.targetRow = null;
    this.targetIdRow = null;
    var src = Event.element(event);
    if (src && (src.tagName.toUpperCase() == 'TH' || src.tagName.toUpperCase() == 'TD')) { 
      this.targetHeaderCell = src;
    } else {
      this.targetHeaderCell = Element.getParentByTagName(['TH,TD'], src);
    }
    if (this.targetHeaderCell) {
      this.targetColIndex = this.targetHeaderCell.cellIndex;
      this.targetColumn = this.getCells(this.targetColIndex);
      this.cssUtil.addClassNames(this.targetHeaderCell, 'cellSelected');
      var childNodes = Element.getTagNodes(this.targetHeaderCell, true);
      for (var i = 0; i < childNodes.length; i++) {
        this.cssUtil.addClassNames(childNodes[i], 'cellSelected');
      }
      for(var i = 0; i < this.targetColumn.length; i++) {
        this.cssUtil.addClassNames(this.targetColumn[i], 'cellSelected');
        var cellChildNodes = Element.getTagNodes(this.targetColumn[i], true);      
        for (var j = 0; j < cellChildNodes.length; j++) {
          this.cssUtil.addClassNames(cellChildNodes.length[j], 'cellSelected');
        }
      }
    }
  },

  setSelectedRow : function(event) {
    this.removeSelectedClasses();
    var src = Event.element(event);
    if (src && src.tagName.toUpperCase() == 'TR') { 
      this.targetIdRow = src;
    } else {
      this.targetIdRow = Element.getParentByTagName(['TR'], src);
    }
    if (this.targetIdRow) {
      this.targetRowIndex = this.targetIdRow.rowIndex;
      this.targetRow = this.getRow(this.targetRowIndex);
      
      this.cssUtil.addClassNames(this.targetRow, 'cellSelected');
      var childNodes = Element.getTagNodes(this.targetRow, true);
      for (var i = 0; i < childNodes.length; i++) {
        this.cssUtil.addClassNames(childNodes[i], 'cellSelected');
      }
      this.cssUtil.addClassNames(this.targetIdRow, 'cellSelected');
      childNodes = Element.getTagNodes(this.targetIdRow, true);
      for (var i = 0; i < childNodes.length; i++) {
        this.cssUtil.addClassNames(childNodes[i], 'cellSelected');
      }  
    }
    
  },
  
  removeSelectedClasses : function() {
    if (this.targetHeaderCell) {
      this.cssUtil.removeClassNames(this.targetHeaderCell, 'cellSelected');
      var childNodes = Element.getTagNodes(this.targetHeaderCell, true);
      for (var i = 0; i < childNodes.length; i++) {
        this.cssUtil.removeClassNames(childNodes[i], 'cellSelected');
      }
      for(var i = 0; i < this.targetColumn.length; i++) {
        this.cssUtil.removeClassNames(this.targetColumn[i], 'cellSelected');
        var cellChildNodes = Element.getTagNodes(this.targetColumn[i], true);      
        for (var j = 0; j < cellChildNodes.length; j++) {
          this.cssUtil.removeClassNames(cellChildNodes.length[j], 'cellSelected');
        }
      }
      
    }
    if (this.targetCell) {
      this.cssUtil.removeClassNames(this.targetCell, 'cellSelected');
      var childNodes = Element.getTagNodes(this.targetCell, true);      
      for (var i = 0; i < childNodes.length; i++) {
        this.cssUtil.removeClassNames(childNodes[i], 'cellSelected');
      }
      
    }
    
    if (this.targetRow) {
      this.cssUtil.removeClassNames(this.targetRow, 'cellSelected');
      var childNodes = Element.getTagNodes(this.targetRow, true);
      for (var i = 0; i < childNodes.length; i++) {
        this.cssUtil.removeClassNames(childNodes[i], 'cellSelected');
      }
      this.cssUtil.removeClassNames(this.targetIdRow, 'cellSelected');
      childNodes = Element.getTagNodes(this.targetIdRow, true);
      for (var i = 0; i < childNodes.length; i++) {
        this.cssUtil.removeClassNames(childNodes[i], 'cellSelected');
      }  
    }
    
    this.targetHeaderCell = null;
    this.targetColumn = null;
    this.targetColIndex = null;
    this.targetCell = null;
    this.targetRowIndex = null;
    this.targetRow = null;
    this.targetIdRow = null;  
  },
  
  updateId : function() {
    var rows = this.idTable.rows;
    for (var i = 0; i < rows.length; i++) {
      var idValue = document.getElementsByClassName(this.custumCss.idCellVal, rows[i])[0];
      
      idValue.innerHTML = i + 1;
    }
  },
  
  updateRowLine : function(target) {
    var targetCellRow = this.cellTable.rows[this.targetRowIndex];
    var updateRowIndex = this.targetIdRow.rowIndex;
    var cellTableBody = targetCellRow.parentNode;
    var cellTableRows = cellTableBody.rows;
    
    if (this.options.hierarchy) {
      var checkRow = cellTableBody.rows[this.targetIdRow.rowIndex];
      if (this.isParentRow(checkRow, targetCellRow)) {
        var idBody = this.idTable.tBodies[0];
        idBody.insertBefore(this.targetIdRow, idBody.rows[this.targetRowIndex]);
        return;
      }
    }
    if (updateRowIndex == cellTableRows.length - 1) {
      cellTableBody.appendChild(targetCellRow);
    } else if (this.targetRowIndex < updateRowIndex) {
      cellTableBody.insertBefore(targetCellRow, cellTableRows[updateRowIndex + 1]);
    } else {
      cellTableBody.insertBefore(targetCellRow, cellTableRows[updateRowIndex]);
    }
    if (this.options.hierarchy) {
      this.updateOutline(targetCellRow);
    }
    this.targetRowIndex = updateRowIndex;
    this.updateId();
  },
  updateCellLine : function(target){
    var targetCells = this.getCells(this.targetColIndex);
    var updateColIndex = this.targetHeaderCell.cellIndex;
    
    var rows = this.cellTable.rows;
    
    for (var i = 0; i < rows.length; i++) {
      var cells = rows[i].cells;
      var targetCell = targetCells[i];
      
      if (updateColIndex == cells.length -1) {
        rows[i].appendChild(targetCell);
      } else if (this.targetColIndex < updateColIndex) {
        rows[i].insertBefore(targetCell, cells[updateColIndex + 1]);
      } else {
        rows[i].insertBefore(targetCell, cells[updateColIndex]);
      }
    }
    this.targetColIndex = updateColIndex;
  },
  
  updateCellWidth : function(newStyle, headColumn) {
    
    if(newStyle.width > this.options.cellMinWidth) {
      var dragDiv = Element.getElementsByClassName(headColumn, Grid.className.headerCellDrag)[0];
      var sortDiv = Element.getElementsByClassName(headColumn, Grid.className.headerCellSort)[0];
      var val = newStyle.width - (parseInt(Element.getStyle(headColumn, 'width')));
      
      val = parseInt(val);
      
      this.headerTable.style.width = (parseInt(Element.getStyle(this.headerTable, 'width')) + val) + 'px';
      
      dragDiv.style.width = newStyle.width - (this.marginSize * 2) + 'px';
      sortDiv.style.width = parseInt(Element.getStyle(dragDiv, 'width')) - (this.marginSize * 2)  + 'px';
      
      var index = headColumn.cellIndex ;
      var rows = this.cellTable.rows;

      this.cellTable.style.width = this.headerTable.style.width
      
      for(var i = 0; i < rows.length; i++){
        var cell = rows[i].cells[index];
        var cellValueDiv = Element.getElementsByClassName(cell, Grid.className.cellVal)[0];
        cellValueDiv.style.width = newStyle.width + 'px';
        cell.style.width = newStyle.width + 'px';
      }
            
    }
  },
  
  updateCellHeight : function(newStyle, idCell) {
    if(newStyle.height > this.options.cellMinHeight) {
      var row = idCell.parentNode;
      var index = row.rowIndex;
      var idValueDiv = Element.getElementsByClassName(idCell, Grid.className.idCellVal)[0];
      idValueDiv.style.height = newStyle.height - (this.marginSize * 2) + 'px';
      var padding = parseInt(idValueDiv.style.paddingTop);
      var cellRow = this.cellTable.rows[index];      
      var cells = cellRow.cells;
      for (var i = 0; i < cells.length; i++) {
        cells[i].style.height = newStyle.height + 'px';
        var cellValueDiv =  Element.getElementsByClassName(cells[i], Grid.className.cellVal)[0];
        cellValueDiv.style.height = newStyle.height + 'px';
      }
    }
  },
  
  setTextAreaSize : function(event) {
    var target = Event.element(event);
    var rows = parseInt(Element.getStyle(target, 'height'));
    var cols = parseInt(Element.getStyle(target, 'width'));
    target.ajax.options.rows = Math.round(rows/20);
    target.ajax.options.cols = Math.round(cols/20);
  },
  
  fixTablePosition : function(event) {
    Grid.scrollTop = this.element.scrollTop;
    Grid.scrollLeft = this.element.scrollLeft;
    this.baseTable.style.top = Grid.scrollTop + 'px';
    this.baseTable.style.left = Grid.scrollLeft + 'px';
    this.headerTable.style.top = Grid.scrollTop + 'px';
    this.idTable.style.left = Grid.scrollLeft + 'px';
  },
  
//----------ajax request param method---------------------------------------------------------------------------
  createInplaceEditorParams : function(form, value) {
    var rowIndexEnd = form.id.indexOf('_col_', 0);
    var rowIndex = form.id.substring(this.rowIdBase.length, rowIndexEnd);

    var colIndexStart = rowIndexEnd + '_col_'.length;
    var colIndexEnd = form.id.indexOf('_form', 0);
    var colIndex = form.id.substring(colIndexStart, colIndexEnd);
    var jsonRowObj = this.rowDataToJsonObj(rowIndex);

    var targetColTitle = this.getColTitle(colIndex);
    jsonRowObj.each(function(j) {
      if (j.column == targetColTitle) {
        j.value = value;
        throw $break;
      }
    });
    var jsonRowText = JSON.stringify(jsonRowObj);
    var params = {
      rowData: jsonRowText,
      column: targetColTitle,
      value: value
    };
    return $H(params).toQueryString();
  },
  
  gridDataToJsonObj : function() {
    var rows = this.cellTable.rows;
    var jsonDataList = [];
    for (var i = 0; i < this.rowLength; i++) {
      var rowData = this.rowDataToJsonObj(i);
      jsonDataList.push(rowData);
    }
    return jsonDataList;  
  },
  
  rowDataToJsonObj : function(index) {
    var jsonRowObj = [];
    var row = $A(this.cellTable.rows).detect(function(r) {return r.id.getSuffix() == index});
    for (var i = 0; i < this.colLength; i++) {
      var jsonCellObj = {};
      jsonCellObj['column'] =  this.getColTitle(i);
      jsonCellObj['value'] = Element.collectTextNodes(row.cells[i]);
      jsonRowObj.push(jsonCellObj);
    }
    return jsonRowObj;
  },
  
  updateGridData : function() {
    
    var jsonDataText = JSON.stringify(this.gridDataToJsonObj());
    var params = 'id=' + encodeURIComponent(this.element.id) + '&data=' + encodeURIComponent(jsonDataText);

    new Ajax.Updater(
      this.options.updateGridReceiver, 
      this.options.updateGridUrl,
      { 
        parameters: params, 
        evalScripts: true, asynchronous:true
        
      }
    );    
  },

//----------hierarchy grid method---------------------------------------------------------------------------
  setHierarchyRow : function(row, outlineLevel, outlineNum){
    row.outlineLevel = outlineLevel || 1;
    row.list = row.list || new Array();
    if (row.outlineLevel == 1) {
      this.topLevelList.push(row);
      row.outlineNum = outlineNum || this.topLevelList.length;
    } else {
      var parentRow = this.getParentRow(row);
      parentRow.list.push(row);
      var num = parentRow.length;
      row.outlineNum = outlineNum || parentRow.outlineNum + '.' + parentRow.list.length;
      
    }
      
    this.buildStateDiv(row.cells[this.hierarchyColIndex]);
    this.setOutlineIndent(row);
    this.setFontWeight(row);
  },
  
  buildStateDiv : function (cell) {
    var stateDiv = Builder.node('div');
    var valueDiv = Element.getElementsByClassName(cell, Grid.className.cellVal)[0];
    this.cssUtil.addClassNames(stateDiv, 'state');
    cell.insertBefore(stateDiv, valueDiv);
    
    if (document.all) {
      stateDiv.style.position = "absolute";
    } else {
      stateDiv.style.position = "relative";
      stateDiv.style.cssFloat = "left";
    }
    this.addStateClass(cell, stateDiv);
    Event.observe(stateDiv, 'click', this.toggleState.bindAsEventListener(this));
  },
  
  addStateClass : function (cell, stateDiv) {
    var row = cell.parentNode;
    if (row.list.length == 0) {
      this.cssUtil.addClassNames(stateDiv, 'stateEmpty');
    } else if (this.options.open){
      this.cssUtil.addClassNames(stateDiv, 'stateOpen');
    } else {
      this.cssUtil.addClassNames(stateDiv, 'stateClose');
      this.closeRow(row);
    }
  },
  
  toggleState : function(event) {
    var src = Event.element(event);
    var row = src.parentNode.parentNode;

    if (!Element.hasClassName(src, Grid.className.stateEmpty)) {
      if (Element.hasClassName(src, Grid.className.stateOpen)) {
        this.closeRow(row.list);
        this.cssUtil.removeClassNames(src, 'stateOpen');
        this.cssUtil.addClassNames(src, 'stateClose');
      } else {
        this.openRow(row.list);
        this.cssUtil.removeClassNames(src, 'stateClose');
        this.cssUtil.addClassNames(src, 'stateOpen');
      }
    }
  },
  
  openRow : function(list) {
    for (var i = 0; i < list.length; i++) {
      var row = list[i];
      Element.show(row);
      Element.show(this.getIdRow(row));
      var stateDiv = Element.getElementsByClassName(row.cells[this.hierarchyColIndex], Grid.className.state)[0];
      if (Element.hasClassName(stateDiv, Grid.className.stateOpen)) {
        this.openRow(row.list)
      }
    }
  },
  
  closeRow : function(list) {
    for (var i = 0; i < list.length; i++) {
      Element.hide(list[i]);
      Element.hide(this.getIdRow(list[i]));
      this.closeRow(list[i].list)
    }  
  },

  
  showStateDiv : function(transport, element) {
    var row = Element.getParentByTagName(['TR'], element);
    var state = Element.getElementsByClassName(row, Grid.className.state)[0];
    Element.show(state);    
  },
  
  hideStateDiv : function(event) {
    var src = Event.element(event);
    var row = Element.getParentByTagName(['TR'], src);
    var state = Element.getElementsByClassName(row, Grid.className.state)[0];
    
    Element.hide(state);
  },
  
  addHierarchyRow : function(index, values) {
    if (this.colLength == 0) {
      return;
    }
    var newRow = this.addRow(index, values);
    
    newRow.list = new Array();
    var previousRow = newRow.previousSibling;
    var parentRow = null;
    var parentList = null;
    var insertIndex = 0;
    if (!previousRow) {
      newRow.outlineLevel = 1;
      parentList = this.topLevelList;
    } else if (previousRow.list.length > 0) {
      newRow.outlineLevel = previousRow.outlineLevel + 1;
      parentRow = previousRow;
      parentList = parentRow.list;
    } else {
      newRow.outlineLevel = previousRow.outlineLevel;
      parentRow = this.getParentRow(previousRow);
      parentList = parentRow ? parentRow.list : this.topLevelList;
      insertIndex = parentList.indexOf(previousRow) + 1;
    }
    parentList.insert(insertIndex, newRow);
    this.buildStateDiv(newRow.cells[this.hierarchyColIndex]);
    for (var i = insertIndex; i < parentList.length; i++) {
      if (parentList[i].outlineLevel != 1) {
        parentList[i].outlineNum = parentRow.outlineNum + '.' + (i + 1);
      } else {
        parentList[i].outlineNum = i + 1;
      }
      this.setOutline(parentList[i]);
    }    
    
  },
  
  deleteHierarchyRow : function(index) {
    if(isNaN(index) || index >= this.rowLength) {
      return;
    }
    var row = this.getRow(index);
    if (!row) {
      return;
    }
    var parentRow = this.getParentRow(row);
    var parentList = parentRow ? parentRow.list : this.topLevelList;
    var removeIndex = parentList.indexOf(row);
    var childList = row.list;
    
    for (var i = 0; i < childList.length; i++) {
      this.deleteChildRow(childList[i]);
    }
    parentList.remove(removeIndex);
    this.deleteRow(index);
    
    for (var i = removeIndex; i < parentList.length; i++) {
      var updateRow = parentList[i];
      if (updateRow.outlineLevel == 1) {
        updateRow.outlineNum = i + 1;
      } else {
        updateRow.outlineNum = this.getParentRow(updateRow).outlineNum + '.' + (i + 1);
      }
      this.setOutline(parentList[i]);
    }
    this.setFontWeight(parentRow);
  },
  
  deleteChildRow : function(childRow) {
    var list = childRow.list;
    
    for (var i = 0; i < list.length; i++) {
      this.deleteChildRow(list[i]);
    }
    this.deleteRow(childRow.rowIndex);
  }, 
  
  levelUp : function(row) {
    if (!row) {
      return;
    }
    var previousRow = row.previousSibling;
    if (row.outlineLevel == 1 || !previousRow) {
      return;
    }
    
    var parentRow = this.getParentRow(row);
    var currentList = parentRow.list;
    
    var newParentRow = this.getParentRow(parentRow);
    var targetList = newParentRow ? newParentRow.list : this.topLevelList;
    
    var currentIndex = currentList.indexOf(row);
    var targetIndex = targetList.indexOf(parentRow) + 1;

    row.outlineLevel -= 1;
    targetList.insert(targetIndex, row);
    currentList.remove(currentIndex);
    
    while (currentList[currentIndex]) {
      var moveRow = currentList[currentIndex];
      row.list.push(moveRow);
      currentList.remove(currentIndex);
    }
    
    if (row.outlineLevel != 1) {
      row.outlineNum = newParentRow.outlineNum + '.' + (targetIndex + 1);
    } else {
      row.outlineNum = targetIndex + 1;
    }
    
    this.setOutline(row);

    for (var i = targetIndex + 1; i < targetList.length; i++) {
      if (targetList[i].outlineLevel != 1) {
        targetList[i].outlineNum = newParentRow.outlineNum + '.' + (i + 1);
      } else {
        targetList[i].outlineNum = i + 1;
      }
      this.setOutline(targetList[i]);
    }

    this.setFontWeight(row);
    this.setFontWeight(parentRow);
    this.setFontWeight(newParentRow);    
    this.setStateClass(row);
    this.setStateClass(previousRow);
  },
  
  levelDown : function(row) {
    if (!row) {
      return;
    }
    var previousRow = row.previousSibling;
    var parentRow = this.getParentRow(row);
    if (!previousRow || parentRow == previousRow) {
      return;
    }
    var currentList = (row.outlineLevel == 1) ? this.topLevelList : parentRow.list;
    var currentIndex = currentList.indexOf(row);
    
    row.outlineLevel += 1;
    
    var newParentRow = this.getParentRow(row);
    var targetList = newParentRow.list;
    var targetIndex = targetList.length;
    
    currentList.remove(currentIndex);
    targetList.push(row);
    
    row.outlineNum = newParentRow.outlineNum + '.' + (targetIndex + 1);
    this.setOutline(row);
    for (var i = currentIndex; i < currentList.length; i++) {
      if (currentList[i].outlineLevel != 1) {
        currentList[i].outlineNum = parentRow.outlineNum + '.' + (i + 1);
      } else {
        currentList[i].outlineNum = i + 1;
      }
      this.setOutline(currentList[i]);
    }
    
    for (var i = targetIndex + 1; i < targetList.length; i++) {
      targetList[i].outlineNum = newParentRow.outlineNum + '.' + (i + 1);
      this.setOutline(targetList[i]);
    }
    
    this.setFontWeight(row);
    this.setFontWeight(parentRow);
    this.setFontWeight(newParentRow);
    this.setStateClass(row);
    this.setStateClass(previousRow);
    
  },
  
  setStateClass : function(row) {
    if (!row.list) return; 
    var stateDiv = Element.getElementsByClassName(row.cells[this.hierarchyColIndex], Grid.className.state)[0];
    
    if (Element.hasClassName(stateDiv, Grid.className.stateEmpty) && row.list.length > 0) {
      this.cssUtil.removeClassNames(stateDiv, 'stateEmpty');
      this.cssUtil.addClassNames(stateDiv, 'stateOpen');
    } else if (!Element.hasClassName(stateDiv, Grid.className.stateEmpty) && row.list.length == 0) {
      this.cssUtil.removeClassNames(stateDiv, 'stateOpen');
      this.cssUtil.addClassNames(stateDiv, 'stateEmpty');
    }
  },
  
  setOutline : function(row) {
    var childList = row.list;
    if (!childList) return;
    for(var i = 0; i < childList.length; i++) {
      var childRow = childList[i];
      childRow.outlineLevel = row.outlineLevel + 1;
      childRow.outlineNum = row.outlineNum + '.' + (i + 1);
      this.setOutline(childRow);
    }
    this.setOutlineIndent(row);  
  },
  
  setOutlineIndent : function(row) {
    var cell = row.cells[this.hierarchyColIndex];
    if (!cell) {
      return;
    }
    var cellValueDiv = Element.getElementsByClassName(cell, Grid.className.cellVal)[0];
    var stateDiv = Element.getElementsByClassName(cell, Grid.className.state)[0];
    if (!stateDiv) return;
    var stateDivWidth = stateDiv.offsetWidth || this.stateDivWidth;
    var left = this.options.hierarchyIndent * (row.outlineLevel - 1);
    var valueLeft = document.all ? left + stateDivWidth : left;
    cellValueDiv.style.left = valueLeft + 'px';
    stateDiv.style.left = left + 'px';
  },
  
  setFontWeight : function(row) {
    if (row) {
      if (!row.list) return;
      if (row.list.length > 0){
        row.style.fontWeight = 'bold';
      } else {
        row.style.fontWeight = 'normal';  
      }
    }
  },
  
  updateOutline : function(row) {
    var previousRow = row.previousSibling;
    var newParentRow = null;
    var insertIndex = 0;
    var newParentList = null;
    
    if (!previousRow.list) return;
    if (!previousRow) {
      newParentList = this.topLevelList;
    }else if(previousRow.list.length > 0) {
      newParentRow = previousRow;
      newParentList = newParentRow.list;
    } else {
      newParentRow = this.getParentRow(previousRow);
      newParentList = newParentRow ? newParentRow.list : this.topLevelList;
      insertIndex = newParentList.indexOf(previousRow) + 1;
    }
    var parentRow = this.getParentRowByIndex(row, this.targetRowIndex);
    var parentList = null;

    var outlineNumBase = '';
    if (parentRow) {
      parentList = parentRow.list;
      outlineNumBase = parentRow.outlineNum + '.';
    } else {
      parentList = this.topLevelList;
      if (!parentList) return;
    }
    var removeIndex = parentList.indexOf(row);
    
    if (parentList == newParentList && removeIndex < insertIndex) {  
      insertIndex -= 1;
      parentList.remove(removeIndex);
      parentList.insert(insertIndex, row);
      for (var i = removeIndex; i < parentList.length; i++) {
        try {
          parentList[i].outlineNum = outlineNumBase + (i + 1);
          this.setOutline(parentList[i]); 
        } catch (e) {}
      }
    
    } else {
      parentList.remove(removeIndex);
      newParentList.insert(insertIndex, row);
      for (var i = removeIndex; i < parentList.length; i++) {
        parentList[i].outlineNum = outlineNumBase + (i + 1);
        this.setOutline(parentList[i]); 
      }
      var newOutlineNumBase = newParentRow ? newParentRow.outlineNum + '.' : '';
      var newOutlineLevelBase = newParentRow ? newParentRow.outlineLevel : 0;
      row.outlineNum = newOutlineNumBase + (insertIndex + 1);
      row.outlineLevel = newOutlineLevelBase + 1;
      for (var i = insertIndex; i < newParentList.length; i++) {
        newParentList[i].outlineNum = newOutlineNumBase + (i + 1);
        this.setOutline(newParentList[i]);
      }
      this.setOutline(row);    
    }
    this.setFontWeight(row);
    this.setStateClass(row);
    if (parentRow) {
      this.setFontWeight(parentRow);
      this.setStateClass(parentRow);
    }
    if (newParentRow) {
      this.setFontWeight(newParentRow);
      this.setStateClass(newParentRow);
    }
    this.updateHierarchyRowLine(row);
  },
  
  updateHierarchyRowLine : function(row, existingRow) {
    if (!row.list) return;
    var rowIndex = row.rowIndex;
    var cellBody = this.cellTable.tBodies[0];
    var idBody = this.idTable.tBodies[0];
    if (!existingRow) {
      existingRow = cellBody.rows[rowIndex + 1]
    }
    
    for (var i = 0; i < row.list.length; i++) {
      if (!existingRow) {
        cellBody.appendChild(row.list[i]);
        idBody.appendChild(this.getIdRow(row.list[i]));
      } else {
        cellBody.insertBefore(row.list[i], existingRow);
        idBody.insertBefore(this.getIdRow(row.list[i]), this.getIdRow(existingRow));
      }
      this.updateHierarchyRowLine(row.list[i], existingRow);
    }
  },
    
  getParentRow : function(row) {
    if (row.outlineLevel == 1) {
      return null;
    }

    var previousRow = row.previousSibling;
    if (!previousRow) {
      return null;
    }
    try {
      while (previousRow.outlineLevel != (row.outlineLevel - 1)) {
        previousRow = previousRow.previousSibling;
      }
      return previousRow;
    } catch (e) {}
  },
  
  getParentRowByIndex : function(row, index) {
    if (row.outlineLevel == 1) {
      return null;
    }
    if (this.targetRowIndex) {
      for(var i = 0; i < this.targetRowIndex + 1; i++) {
        if (!this.cellTable.rows[i].list) return;
        if (this.cellTable.rows[i].list.indexOf(row) != -1) {
          return this.cellTable.rows[i];
        }
      }
    }
    return null;
  },
  
  getPreviousRootRow : function(row) {
    var previousRow = row.previousSibling;
    if (!previousRow) {
      return;
    }
    while (previousRow.outlineLevel != 1) {
      previousRow = previousRow.previousSibling;
    }  
    
    return previousRow;
  },
  
  isParentRow : function(row, parentRow) {
    var temp = this.getParentRow(row);
    if (!temp) {
      return false;
    } else if (temp == parentRow) {
      return true;
    } else {
      return this.isParentRow(temp, parentRow);
    }
  }
}
