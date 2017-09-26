function SS_TreeNavi(selector) {
  this.el  = $(selector);
}

SS_TreeNavi.prototype.call = function(url) {
  var _this = this;
  $.ajax({
    url: url,
    beforeSend: function() {
      var height;
      if (height = _this.el.height()) {
        _this.el.html('<div class="loading" style="height: ' + height + 'px">Loading..</div>');
      }
    },
    success: function(data) {
      _this.el.html('');
      _this.render(data);
      _this.registerEvents();
    }
  });
};

SS_TreeNavi.prototype.registerEvents = function() {
  var _this = this;
  this.el.find('.item-mark').click(function() {
    _this.call($(this).attr('href'));
    return false;
  });
};

SS_TreeNavi.prototype.render = function(data) {
  var _this = this;
  $.each(data.items, function(key, item) {
    var cls = [];
    var mark = '<i class="material-icons">&#xE145;</i>';

    if (item.is_parent) {
      cls.push('is-parent');
      mark = '<i class="material-icons">&#xE15B;</i>';
    }
    if (item.is_current) {
      cls.push('is-current');
      mark = '<i class="material-icons">&#xE15B;</i>';
    }

    _this.el.append('<div class="tree-item ' + cls.join(' ') + '">' +
      '<div class="item-pad"></div>'.repeat(item.depth - 1) +
      '<a class="item-mark" href="' + item.tree_url + '">' + mark + '</a>' +
      '<a class="item-name" href="' + item.url + '">' + item.name.replace('<','') + '</a>' +
      '</div>');
  });
};
