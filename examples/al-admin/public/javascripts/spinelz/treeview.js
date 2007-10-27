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

var TreeView = Class.create();
TreeView.className = {
  top:                'treeview',
  dir:                'treeview_dir',
  dirBody:            'treeview_dirBody',
  dirBodyText:        'treeview_dirBodyText',
  dirBodyTextActive:  'treeview_dirBodyTextActive',
  dirContainer:       'treeview_dirContainer',
  dirContainerHover:  'treeview_dirContainerHover',
  file:               'treeview_file',
  fileBody:           'treeview_fileBody',
  fileBodyText:       'treeview_fileBodyText',
  fileBodyTextActive: 'treeview_fileBodyTextActive',
  state_open:         'treeview_stateOpen',
  state_close:        'treeview_stateClose',
  state_empty:        'treeview_stateEmpty',
  dirIcon:            'treeview_dirIcon',
  fileIcon:           'treeview_fileIcon',
  handle:             'treeview_handle'
}

TreeView.iconId = 'treeview_icon';

TreeView.prototype = {
  initialize: function(element) {
    this.options = Object.extend({
      dirSymbol:         'dir',
      fileSymbol:        'file',
      cssPrefix:         'custom_',
      open:              true,
      callBackFunctions: false,
      dirSelect:         true,
      fileSelect:        true,
      noSelectedInsert:  true,
      iconIdPrefix:      TreeView.iconId,
      move:              false,
      unselected:        Prototype.emptyFunction,
      enableUnselected:  true,
      sortOptions:       {},
      openDir:           Prototype.emptyFunction,
      closeDir:          Prototype.emptyFunction,
      emptyImg:          false,
      initialSelected:   null,
      build:             true
    }, arguments[1] || {});

    this.element = $(element);
    this.customCss = CssUtil.appendPrefix(this.options.cssPrefix, TreeView.className);
    this.classNames = new CssUtil([TreeView.className, this.customCss]);

    if (this.options.build) {
      Element.setStyle(this.element, {visibility: 'hidden'});
      Element.hide(this.element);

      this.idCount = 0;
      this.fileIds = [];
      this.dirIds = [];
      this.buildTreeView(this.element);
      this.observeEvent();

      this.classNames.addClassNames(this.element, 'top');
      Element.setStyle(this.element, {visibility: 'visible'});
      Element.show(this.element);

      if (this.options.initialSelected) {
        this.selectEffect(this.options.initialSelected);
      }

      if (this.options.move) this.setSortable();
    }
  },

  open: function(element) {
    this._toggle(element, Element.show);
  },

  openAll: function() {
    var nodes = this.element.getElementsByTagName('ul');
    $A(nodes).each(function(node) {
      Element.show(node);
      this.refreshStateImg(node.parentNode);
    }.bind(this));
  },

  close: function(element) {
    this._toggle(element, Element.hide);
  },

  closeAll: function() {
    var nodes = this.element.getElementsByTagName('ul');
    $A(nodes).each(function(node) {
      Element.hide(node);
      this.refreshStateImg(node.parentNode);
    }.bind(this));
  },

  addChildById: function(element, parent, number) {
    this.fileIds = [];
    this.dirIds = [];
    element = $(element);
    parent = $(parent);

    var container = null;
    if (!element || !parent)
      return;
    else if (Element.hasClassName(parent, TreeView.className.dir))
      container = this.getChildDirContainer(parent);
    else if (Element.hasClassName(parent, TreeView.className.top))
      container = parent;
    else
      return;

    element = this.build(element).toElement();
    if (isNaN(number)) {
      container.appendChild(element);
    } else {
      var children = this.getDirectoryContents(container);
      if (children[number]) container.insertBefore(element, children[number]);
      else container.appendChild(element);
    }

    this.refreshStateImg(parent);
    this.observeEvent();
    if (this.options.dragAdrop) this.setSortable();
  },

  addChildByPath: function(element, path) {
    this.fileIds = [];
    this.dirIds = [];
    element = $(element);
    if (!element) return;

    element = this.build(element).toElement();
    var paths = path.split('/').findAll(function(elm) { return (elm != '') });
    var last = paths.pop();
    var container = this.search(paths.join('/'));
    var children = this.getDirectoryContents(container);

    if(children[last])
      container.insertBefore(element, children[last]);
    else
      container.appendChild(element);

    this.refreshStateImg(container.parentNode);
    this.observeEvent();
    if (this.options.dragAdrop) this.setSortable();
  },

  addChildBySelected: function(element, number) {
    if (!this.selected && !this.options.noSelectedInsert) return;

    if (this.selected)
      this.addChildById(element, this.selected, number);
    else
      this.addChildById(element, this.element, number);
  },

  addSelectItemCallback: function(functionObj) {
    if (!this.options.callBackFunctions) {
      this.options.callBackFunctions = new Array();
    }
    this.options.callBackFunctions.push(functionObj);
  },

  buildTreeView: function(element) {
    this.classNames.addClassNames(element, 'top');
    element.innerHTML = $A(element.childNodes).inject('', function(html, node) {
      return html + this.build(node);
    }.bind(this));
  },

  build: function(element) {
    if (!Element.isElementNode(element)) return '';
    
    if (Element.hasClassName(element, this.options.dirSymbol)) {
      return this.buildDir(element);
    } else if (Element.hasClassName(element, this.options.fileSymbol)) {
      return this.buildFile(element);
    }
  },

  buildDir: function(element) {
    var customClass = new Element.ClassNames(element).select(function(name) {
      return name != this.options.dirSymbol;
    }.bind(this)).join(' ');

    var baseId = element.id || this.getBaseId();
    var state = this.getState(element);
    var iconId = this.options.iconIdPrefix.appendSuffix(baseId);
    var stateId = iconId.appendSuffix('stateImg');
    var bodyTextId = iconId.appendSuffix('dirBodyText');
    var iconClass = [
      this.classNames.joinClassNames('dirIcon'),
      customClass,
      this.classNames.joinClassNames('handle')
    ];
    var display = (this.options.open) ? 'block' : 'none';
    this.dirIds.push({state: stateId, icon: iconId, bodyText: bodyTextId});

    var html =
      "<li id='" + baseId + "' class='" + this.classNames.joinClassNames('dir') + "'>" + 
        "<div class='" + this.classNames.joinClassNames('dirBody') + "'>" +
          "<div id='" + stateId + "' class='" + this.classNames.joinClassNames(state) + "'></div>" +
          "<div id='" + iconId + "' class='" + iconClass.join(' ') + "'></div>" +
          "<span id='" + bodyTextId + "'class='" + this.classNames.joinClassNames('dirBodyText') + "'>" +
            this.getDirectoryText(element) +
          "</span>" +
        "</div>" +
        "<ul style='display: " + display + "' class='" + this.classNames.joinClassNames('dirContainer') + "'>" +
          this.buildSubContent(element) +
        "</ul>" +
      "</li>";
    return html;
  },

  buildSubContent: function(element) {
    var ul = $A(element.childNodes).detect(function(node) { return Element.hasTagName(node, 'ul') });
    if (ul) {
      return $A(ul.childNodes).inject('', function(html, node) {
        return html + this.build(node);
      }.bind(this));
    } else {
      return '';
    }
  },

  getState: function(element) {
    if (!this.hasChildNodes(element) && !this.options.emptyImg) {
      return 'state_empty';
    } else if (this.options.open) {
      return 'state_open';
    } else {
      return 'state_close';
    }
  },

  hasChildNodes: function(element) {
    var ul = $A(element.childNodes).detect(function(node) { return Element.hasTagName(node, 'ul') });
    return ul && (ul.childNodes.length != 0);
  },

  buildFile: function(element) {
    var customClass = new Element.ClassNames(element).select(function(name) {
      return name != this.options.fileSymbol
    }.bind(this)).join(' ');

    var baseId = element.id || this.getBaseId();
    var iconId = this.options.iconIdPrefix.appendSuffix(baseId);
    var iconClass = [
      this.classNames.joinClassNames('fileIcon'),
      customClass,
      this.classNames.joinClassNames('handle')
    ];
    var bodyTextId = baseId.appendSuffix('fileBodyText');
    this.fileIds.push({icon: iconId, bodyText: bodyTextId});

    // Too late
//    var events = Element.eventHTML(element);
      var events = Element.attributeHTML(element, 'onclick');
    
    var html =
//      "<li id='" + baseId + "' class='" + this.classNames.joinClassNames('file') + "' " + events + ">" + 
      "<li id='" + baseId + "' class='" + this.classNames.joinClassNames('file') + "' " + events + ">" + 
        "<div class='" + this.classNames.joinClassNames('fileBody') + "'>" +
          "<div id='" + iconId + "' class='" + iconClass.join(' ') + "'></div>" +
          "<span id='" + bodyTextId + "'class='" + this.classNames.joinClassNames('fileBodyText') + "'>" +
            element.innerHTML +
          "</span>" +
        "</div>" +
      "</li>";
    return html;
  },

  getBaseId: function() {
    return this.element.id.appendSuffix(++this.idCount);
  },

  observeEvent: function() {
    this.observeDirEvent();
    if (this.options.fileSelect) this.observeFileEvent();
  },

  observeDirEvent: function() {
    this.dirIds.each(function(idSet) {
      Event.observe(idSet.state, "click", this.toggle.bindAsEventListener(this));
      if (this.options.dirSelect) {
        Event.observe(idSet.icon, "click", this.selectDirItem.bindAsEventListener(this));
        Event.observe(idSet.bodyText, "click", this.selectDirItem.bindAsEventListener(this));
      }
    }.bind(this));
  },

  observeFileEvent: function() {
    this.fileIds.each(function(idSet) {
      Event.observe(idSet.icon, "click", this.selectFileItem.bindAsEventListener(this));
      Event.observe(idSet.bodyText, "click", this.selectFileItem.bindAsEventListener(this));
    }.bind(this));
  },

  convertJSON: function() {
    return JSON.stringify(this.parse());
  },

  getChildBody: function(element) {
    var names = [TreeView.className.fileBody, TreeView.className.dirBody];
    return Element.getFirstElementByClassNames(element, names);
  },

  getChildBodyText: function(element) {
    var names = [
      TreeView.className.fileBodyText,
      TreeView.className.fileBodyTextActive,
      TreeView.className.dirBodyText,
      TreeView.className.dirBodyTextActive
    ];
    return Element.getFirstElementByClassNames(element, names);
  },

  getChildBodyTextNode: function(element) {
    var body = this.getChildBody(element);
    var bodyText = this.getChildBodyText(body);
    return this.searchTextNode(bodyText);
  },

  getChildDir: function(element) {
    return document.getElementsByClassName(TreeView.className.dir, element);
  },

  getChildDirBody: function(element) {
    return document.getElementsByClassName(TreeView.className.dirBody, element)[0];
  },

  getChildDirContainer: function(element) {
    return document.getElementsByClassName(TreeView.className.dirContainer, element)[0];
  },

  getChildStateImg: function(element) {
    var body = this.getChildDirBody(element);
    var names = [
      TreeView.className.state_close,
      TreeView.className.state_open,
      TreeView.className.state_empty
    ];

    return Element.getFirstElementByClassNames(body, names);
  },

  getChildren: function(element, ignoreDir, ignoreFile) {
    var parent;
    var children = new Array();
    if(element) {
      parent = $(element).getElementsByTagName('ul')[0];
    } else {
      parent = this.element;
    }
    $A(Element.getTagNodes(parent)).each(
      function(node) {
        if(!ignoreDir && Element.hasClassName(node, TreeView.className.dir)) {
          children.push(node);
        }
        if(!ignoreFile && Element.hasClassName(node, TreeView.className.file)) {
          children.push(node);
        }
      }
    );
    return children;
  },

  getDirectoryContents: function(element) {
    return $A(element.childNodes).findAll(function(child) {
      if ((child.nodeType != 1)) {
        return false;
      }
      if (child.tagName.toLowerCase() == 'li') {
        return true;
      }
      return false;
    });
  },

  getDirectoryText: function(element) {
    return $A(element.childNodes).inject('', function(html, node) {
      if (Element.isTextNode(node)) {
        html += node.nodeValue;
      } else if (node.tagName.toLowerCase() != 'ul') {
        html += Element.outerHTML(node);
      }
      return html;
    });
  },

  getHierarchyNumber: function() {
    if (!this.selected) return;
    var element = this.selected;
    var i = 0;
    while (true) {
      if (this.element == element) {
        return i;
      } else {
        element = this.getParentDir(element, true);
        if (!element) return;
        i++;
      }
    }
  },

  ancestor: function() {
    var arr = [];
    if(this.selected) {
      var element = this.selected;
      arr.push(element);
      while(element) {
        element = this.getParentDir(element, false);
        if(element) {
          arr.push(element);
        }
      }
    }
    return arr.reverse();
  },

  getParentDir: function(element, top) {
    var result = Element.getParentByClassName(TreeView.className.dir, element);
    if (!result && top)
      result = Element.getParentByClassName(TreeView.className.top, element);
    return result;
  },

  hasContents: function(element) {
    if (element) {
      if (!Element.hasClassName(element, TreeView.className.dirContainer) &&
          !Element.hasClassName(element, TreeView.className.top)) {
        return false;
      }

      var nodes = element.childNodes;
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].nodeType == 1) {
          if (Element.hasClassName(nodes[i], TreeView.className.dir) ||
              Element.hasClassName(nodes[i], TreeView.className.file)) {
            return true;
          }
        }
      }
    }
    return false;
  },

  parse: function(container) {
    if (!container) container = this.element;

    var itemList = [];
    var contents = this.getDirectoryContents(container);

    for (var i = 0; i < contents.length; i++) {
      var node = contents[i];
      var body = this.getChildBody(node);
      var text = this.getChildBodyText(body);

      var item = {};
      item.id = node.id;

      item.name = Element.collectTextNodes(text).replace(/\n/, '');
      if (Element.hasClassName(node, TreeView.className.dir)) {
        item.type = this.options.dirSymbol;
        item.contents = this.parse(this.getChildDirContainer(node));

      } else {
        item.type = this.options.fileSymbol;
       }

       itemList.push(item);
    }

    return itemList;
  },

  refreshStateImg: function(element) {
    if (!Element.hasClassName(element, TreeView.className.dir)) return;

    var container = this.getChildDirContainer(element);
    var img = this.getChildStateImg(element);

    if (!this.hasContents(container) && !this.options.emptyImg)
      this.classNames.refreshClassNames(img, 'state_empty');
    else if (Element.visible(container))
      this.classNames.refreshClassNames(img, 'state_open');
    else
      this.classNames.refreshClassNames(img, 'state_close');
  },

  removeById: function(element) {
    element = $(element);
    if (element) {
      var parent = element.parentNode.parentNode;
      Element.remove(element);
      this.refreshStateImg(parent);
    }
  },

  removeByPath: function(path) {
    var paths = path.split('/').findAll(function(elm) {
      return (elm != '');
    });

    var last = paths.pop();
    var container = this.search(paths.join('/'));

    var target = this.getDirectoryContents(container)[last];
    if (target)
      this.removeById(target);
  },

  removeBySelected: function() {
    if (!this.selected) return;
    this.removeById(this.selected);
    this.selected = false;
  },

  renameById: function(name, element) {
    element = $(element);
    if (!Element.hasClassName(element, TreeView.className.dir) &&
        !Element.hasClassName(element, TreeView.className.file)) {
      return;
    }
    var node = this.getChildBodyTextNode(element);
    node.nodeValue = name;
  },

  renameByPath: function(name, path) {
    var paths = path.split('/').findAll(function(elm) {
      return (elm != '');
    });

    var last = paths.pop();
    var container = this.search(paths.join('/'));

    var target = this.getDirectoryContents(container)[last];
    if (target)
      this.renameById(name, target);
  },

  renameBySelected: function(name) {
    if (!this.selected) return;
    this.renameById(name, this.selected);
  },

  search: function(path) {
    var paths = path.split('/').findAll(function(elm) {
      return (elm != '');
    });

    var container = this.element;
    for (var i = 0; i < paths.length; i++) {
      var num = paths[i];
      var contents = this.getDirectoryContents(container);
      if (contents[num] && Element.hasClassName(contents[num], TreeView.className.dir)) {
        container = this.getChildDirContainer(contents[num]);
      } else {
        return false;
      }
    }
    return container;
  },

  searchTextNode: function(element) {
    var text = null;
    var nodes = element.childNodes;

    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].nodeType == 3) {
        text = nodes[i];
        break;
      } else if (nodes[i].nodeType == 1) {
        var tmp = this.searchTextNode(nodes[i]);
        if (tmp) {
          text = tmp;
          break;
        }
      }
    }
    return text;
  },

  selectDirItem: function(event) {
    var itemBody = Element.getParentByClassName(TreeView.className.dirBody, Event.element(event));
    this.selectItem(itemBody);
  },

  selectEffect: function(element) {
    element = $(element);
    if(element) {
      var itemBody = $A(element.childNodes).detect(function(node) { return Element.isElementNode(node); });
      if (this.selectItemUnselect(itemBody, false)) {
        return;
      }
      this.selectItemSelect(itemBody, false);
    }
  },

  selectFileItem: function(event) {
    var itemBody = Element.getParentByClassName(TreeView.className.fileBody, Event.element(event));
    this.selectItem(itemBody);
  },

  selectItem: function(itemBody) {
    if (this.selectItemUnselect(itemBody, true)) {
      return;
    }
    this.selectItemSelect(itemBody, true);
  },

  selectItemSelect: function(itemBody, callback) {
    this.selected = itemBody.parentNode;
    var text = this.getChildBodyText(itemBody);
    if (Element.hasClassName(text, TreeView.className.dirBodyText)) {
      this.classNames.refreshClassNames(text, 'dirBodyTextActive');
      this.defaultCss = 'dirBodyText';
    } else if (Element.hasClassName(text, TreeView.className.fileBodyText)) {
      this.classNames.refreshClassNames(text, 'fileBodyTextActive');
      this.defaultCss = 'fileBodyText';
    }
    if (callback) {
      if (this.options.callBackFunctions) {
        for (var i = 0; i < this.options.callBackFunctions.length; i++) {
          this.options.callBackFunctions[i](itemBody.parentNode);
        }
      }
    }
  },

  selectItemUnselect: function(itemBody, callback) {
    if (this.selected) {
      var selectedBody = this.getChildBody(this.selected);
      var selectedText = this.getChildBodyText(selectedBody);
      this.classNames.refreshClassNames(selectedText, this.defaultCss);
      if (this.selected == itemBody.parentNode && this.options.enableUnselected) {
        this.selected = false;
        this.defaultCss = false;
        if (callback) {
          this.options.unselected();
        }
        return true;
      }
    }
    return false;
  },

  setSortable: function() {
    var options = Object.extend({
      dropOnEmpty: true,
      tree:        true,
      hoverclass:  'treeview_dirContainerHover',
      scroll:      window,
      ghosting:    true
    }, this.options.sortOptions);
    Sortable.create(this.element, options);
  },

  toggle: function(event) {
    Event.stop(event);
    var src = Event.element(event);
    this._toggle(this.getParentDir(src), Element.toggle);
  },

  _toggle: function(element, method) {
    element = $(element);
    if (element && !Element.hasClassName(element, TreeView.className.dir)) return;
    var container = this.getChildDirContainer(element);
    if (!this.hasContents(container) && !this.options.emptyImg) return;

    method(container);
    this.refreshStateImg(element);

    if (!this.hasContents(container) && !this.options.emptyImg)
      this.options.openDir(element, container);
    else if (Element.visible(container))
      this.options.openDir(element, container);
    else
      this.options.closeDir(element, container);
  }
}
