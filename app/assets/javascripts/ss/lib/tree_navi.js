function SS_TreeNavi(selector) {
  this.el = $(selector);
  this.closeMark = '<i class="material-icons">&#xE145;</i>';
  this.openMark = '<i class="material-icons">&#xE15B;</i>';
}

SS_TreeNavi.prototype.render = function(url) {
  var _this = this;
  var loading = $(SS.loading);

  $.ajax({
    url: url,
    beforeSend: function() {
      if (_this.errorEl) {
        _this.errorEl.hide();
      }
      _this.el.append(loading);
    },
    success: function(data) {
      _this.el.append(_this.renderItems(data.items));
      _this.registerEvents();
    },
    error: function(xhr, status, error) {
      _this.showError(xhr, status, error);
    },
    complete: function() {
      loading.remove();
    }
  });
};

SS_TreeNavi.prototype.renderChildren = function(item) {
  var _this = this;
  var loading = $(SS.loading);

  $.ajax({
    url: $(item).find('.item-mark').attr('href'),
    data: 'only_children=1',
    beforeSend: function() {
      if (_this.errorEl) {
        _this.errorEl.hide();
      }
      item.after(loading);
    },
    success: function(data) {
      item.after(_this.renderItems(data.items));
      _this.registerEvents();
    },
    error: function(xhr, status, error) {
      _this.showError(xhr, status, error);
    },
    complete: function() {
      loading.remove();
    }
  });
  return false;
};

SS_TreeNavi.prototype.renderItems = function(data) {
  var _this = this;
  return $.map(data, function(item) {
    var is_open = item.is_current || item.is_parent
    var mark = is_open ? _this.openMark : _this.closeMark;
    var cls = is_open ? ['is-open is-cache'] : ['is-close'];
    if (item.is_current) cls.push('is-current');

    return '<div class="tree-item ' + cls.join(' ') + '" data-filename="' + item.filename + '">' +
      '<div class="item-pad"></div>'.repeat(item.depth - 1) +
      '<a class="item-mark" href="' + item.tree_url + '">' + mark + '</a>' +
      '<a class="item-name" href="' + item.url + '">' + item.name.replace('<','') + '</a>' +
      '</div>';
  });
};

SS_TreeNavi.prototype.registerEvents = function() {
  var _this = this;
  _this.el.find('.tree-item').not('.is-event').each(function() {
    var item = $(this);
    item.addClass('is-event');

    item.find('.item-mark').click(function() {
      if (item.hasClass('is-open')) {
        _this.closeItem(item, $(this));
      } else {
        _this.openItem(item, $(this));
      }
      return false;
    });
  });
};

SS_TreeNavi.prototype.openItem = function(item, mark) {
  item.addClass('is-open');
  mark.html(this.openMark);

  if (!item.hasClass('is-cache')) {
    this.renderChildren(item);
    return;
  }
  this.el.find('.tree-item').each(function(){
    if ($(this).data('filename').startsWith(item.data('filename') + '/')) {
      $(this).show();
    }
  });
};

SS_TreeNavi.prototype.closeItem = function(item, mark) {
  item.addClass('is-cache');
  item.removeClass('is-open');
  mark.html(this.closeMark);

  this.el.find('.tree-item').each(function() {
    if ($(this).data('filename').startsWith(item.data('filename') + '/')) {
      $(this).hide();
    }
  });
};

SS_TreeNavi.prototype.showError = function(xhr, status, error) {
  if (! this.errorEl) {
    this.errorEl = $('<div class="error" />');
    this.el.append(this.errorEl);
    this.errorEl.hide();
  }

  this.errorEl.html(error);
  this.errorEl.show();
};
