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

var AjaxHistory = {
  _callback:            {},
  _alwaysHashGen:       null,
  _currentIframeHash:   '',
  _currentLocationHash: '',
  _prefix:              'ajax_history_',
  _ignoreOnce:          false,
  add: function(value, options) {
    if(!options) options = {};
    this._ignoreOnce = options.ignoreOnce;
    var currentHash = (options.prefix ? (options.prefix + '_') : this._prefix) + value;
    if(this._alwaysHashGen && !options.ignoreAlwaysHash) {
      var alwaysHash = this._alwaysHashGen();
      currentHash = alwaysHash + '|' + currentHash;
    }
    AjaxHistoryPageManager.setHash(currentHash);
  },
  checkIframeHash: function() {
    var iframeHash = AjaxHistoryIframeManager.getHash();
    if(this._currentIframeHash != iframeHash) {
      this._currentIframeHash = iframeHash;
      this._currentLocationHash = iframeHash;
      AjaxHistoryPageManager.setHash((iframeHash) ? iframeHash : '');
      this.doEvent(iframeHash);
    } else {
      this.checkLocationHash();
    }
  },
  checkHash: function() {
    if(UserAgent.isIE()) {
      this.checkIframeHash();
    } else {
      this.checkLocationHash();
    }
  },
  checkLocationHash: function() {
    var locationHash = AjaxHistoryPageManager.getHash();
    if(this._currentLocationHash != locationHash) {
      this._currentLocationHash = locationHash;
      if(UserAgent.isIE()) {
        AjaxHistoryIframeManager.setHash(locationHash);
      } else {
        this.doEvent(locationHash);
      }
    }
  },
  doEvent: function(hash) {
    if(this._ignoreOnce) {
      this._ignoreOnce = false;
      return;
    }
    var splitted_hash = $A(hash.split('|'));
    for(var each_cb_key in this._callback){
      var each_cb = this._callback[each_cb_key];
      splitted_hash.each(
        function(each_hash) {
          if(each_hash.match(new RegExp('^' + each_cb_key))) {
            var fixed_id = each_hash.replace(each_cb_key, '');
            each_cb.call(null, each_hash.replace(each_cb_key, ''));
          }
        }
      );
    }
  },
  init: function(callback, prefix) {
    this.addCallback(callback, prefix)
    if(UserAgent.isIE()) {
      AjaxHistoryIframeManager.create();
    }
    var self = this;
    var hashHandler = function() {self.checkHash();}
    setInterval(hashHandler, 100);
  },
  addCallback: function(callback, prefix){
    var current_prefix = prefix ? (prefix + '_') : this._prefix;
    this._callback[current_prefix] = callback;
  },
  setAlwaysHashGen: function(alwaysHashGen){
    this._alwaysHashGen = alwaysHashGen;
  }
}

var AjaxHistoryIframeManager = {
  _id :         'ajax_history_frame',
  _element:     null,
  _src:         IECover.src,
  create: function() {
    document.write('<iframe id="' + this._id + '" src="' + this._src + '" style="display: none;"></iframe>');
    this._element = $(this._id);
  },
  getHash: function() {
    try{
      var iframeDocument = this._element.contentWindow.document;
      return unescape(iframeDocument.location.hash.replace(/^#/, ''));
    } catch(e) {
      return ''
    }
  },
  setHash: function(query) {
    var iframeDocument = this._element.contentWindow.document;
    iframeDocument.open();
    iframeDocument.close();
    iframeDocument.location.hash = escape(query);
  }
}

var AjaxHistoryPageManager = {
  _delimiter:   '#',
  _location:    'window.location.href',
  _query:       '',
  getLocation: function() {
    return eval(this._location);
  },
  getHash: function() {
    var url_elements = this.getLocation().split(this._delimiter);
    return unescape((url_elements.length > 1) ? url_elements[url_elements.length - 1] : this._query);
  },
  getSpecifiedValue: function(key) {
    var result = '';
    $A(this.getHash().split('|')).each(
      function(hash) {
        if(hash.match(new RegExp('^' + key + '_'))) {
          result = hash.replace(key + '_', '');
        }
      }
    );
    return result;
  },
  getUrl: function() {
    var url_elements = this.getLocation().split(this._delimiter);
    return url_elements[0];
  },
  setHash: function(query) {
    window.location.hash = escape(query);
  }
}
