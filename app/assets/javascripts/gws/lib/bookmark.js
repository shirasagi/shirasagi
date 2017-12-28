function Gws_Bookmark() {
  this.bookmark_id = null;
  this.default_name = null;
  this.url = null;
  this.model = null;
  this.el = $('.gws-bookmark');
  this.bookmark_icon = "&#xE866;";
  this.unbookmark_icon = "&#xE867;";
  this.loading = false;
};

Gws_Bookmark.prototype.render = function(opts) {
  var _this, icon, bookmark_name, span, ul, li;
  if (opts === null) {
    opts = {};
  }
  _this = this;
  _this.bookmark_id = opts['id'];
  _this.default_name = opts['default_name'];
  _this.url = opts['url'];
  _this.model = opts['model'];

  if (_this.bookmark_id) {
    icon = _this.bookmark_icon;
  } else {
    icon = _this.unbookmark_icon;
  }
  bookmark_name = opts['name'] || _this.default_name;

  span = $('<span class="bookmark-icon"></span>');
  span.append($('<i class="material-icons">' + icon + '</i>'));
  _this.el.html(span);
  ul = $('<ul class="dropdown-menu"></ul>');
  ul.append($('<li><div class="bookmark-notice"></div></li>'));
  li = $('<li></li>');
  li.append($('<input name="bookmark[name]" id="bookmark_name" class="bookmark-name" type="text">').val(bookmark_name));
  li.append($('<input name="button" type="button" class="btn update" />').val(opts['save']));
  li.append($('<input name="button" type="button" class="btn delete" />').val(opts['delete']));
  ul.append(li);
  _this.el.append(ul);

  _this.el.click(function(e) {
    if (_this.loading) {
      return false;
    } else if ($(e.target).hasClass('update')) {
      _this.update();
    } else if ($(e.target).hasClass('delete')) {
      _this.delete();
    } else if (_this.bookmark_id) {
      _this.el.addClass('active');
      _this.el.find('.dropdown-menu').addClass('active');
    } else {
      _this.create();
    }
  });
};

Gws_Bookmark.prototype.create = function() {
  loading = true;
  var _this, html;
  _this = this;
  html = _this.el.find('.dropdown-menu').html();
  _this.el.find('.dropdown-menu').html(SS.loading);
  $.ajax({
    url: _this.url,
    method: 'POST',
    data: {
      item: {
        name: _this.default_name,
        url: location.pathname,
        model: _this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.addClass('active');
      _this.el.find('.dropdown-menu').addClass('active');
      _this.el.find('.material-icons').html(_this.bookmark_icon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(_this.default_name);
      _this.bookmark_id = data['bookmark_id'];
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};

Gws_Bookmark.prototype.update = function() {
  loading = true;
  var _this, html, new_name, uri;
  _this = this;
  new_name = _this.el.find('.bookmark-name').val() || _this.default_name;
  uri = _this.url + '/' + _this.bookmark_id;
  html = _this.el.find('.dropdown-menu').html();
  _this.el.find('.dropdown-menu').html(SS.loading);
  _this.el.addClass('active');
  _this.el.find('.dropdown-menu').addClass('active');
  $.ajax({
    url: uri,
    method: 'POST',
    data: {
      _method: 'patch',
      item: {
        name: new_name,
        url: location.pathname,
        model: _this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.bookmark_icon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(new_name);
      _this.bookmark_id = data['bookmark_id'];
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};

Gws_Bookmark.prototype.delete = function() {
  var _this, html, uri;
  _this = this;
  if (!_this.bookmark_id) {
    return false;
  }
  _this.loading = true;
  uri = _this.url + '/' + _this.bookmark_id;
  html = _this.el.find('.dropdown-menu').html();
  _this.el.find('.dropdown-menu').html(SS.loading);
  _this.el.addClass('active');
  _this.el.find('.dropdown-menu').addClass('active');
  $.ajax({
    url: uri,
    method: 'POST',
    data: {
      _method: 'delete',
      item: {
        url: location.pathname
      }
    },
    success: function() {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.unbookmark_icon);
      _this.bookmark_id = null;
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};
