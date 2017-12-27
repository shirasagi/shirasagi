this.Gws_Bookmark = (function() {
  function Gws_Bookmark() {}

  this.bookmark_id = null;
  this.default_name = null;
  this.url = null;
  this.model = null;
  this.el = null;
  this.bookmark_icon = "&#xE866;";
  this.unbookmark_icon = "&#xE867;";
  this.loading = false;

  Gws_Bookmark.render = function(opts) {
    if (opts === null) {
      opts = {};
    }
    bookmark_id = opts['id'];
    default_name = opts['default_name'];
    url = opts['url'];
    model = opts['model'];
    el = $('.gws-bookmark');

    var icon, bookmark_name, span, ul, li;
    if (bookmark_id) {
      icon = bookmark_icon;
    } else {
      icon = unbookmark_icon;
    }
    bookmark_name = opts['name'] || default_name;

    span = $('<span class="bookmark-icon"></span>');
    span.append($('<i class="material-icons">' + icon + '</i>'));
    el.html(span);
    ul = $('<ul class="dropdown-menu"></ul>');
    ul.append($('<li><div class="bookmark-notice"></div></li>'));
    li = $('<li></li>');
    li.append($('<input name="bookmark[name]" id="bookmark_name" class="bookmark-name" type="text">').val(bookmark_name));
    li.append($('<input name="button" type="button" class="btn update" />').val(opts['save']));
    li.append($('<input name="button" type="button" class="btn delete" />').val(opts['delete']));
    ul.append(li);
    el.append(ul);

    el.click(function(e) {
      if (loading) {
        return false;
      } else if ($(e.target).hasClass('update')) {
        Gws_Bookmark.update();
      } else if ($(e.target).hasClass('delete')) {
        Gws_Bookmark["delete"]();
      } else if (bookmark_id) {
        el.addClass('active');
        el.find('.dropdown-menu').addClass('active');
      } else {
        Gws_Bookmark.create();
      }
    });
  };

  Gws_Bookmark.create = function() {
    loading = true;
    var html;
    html = el.find('.dropdown-menu').html();
    el.find('.dropdown-menu').html(SS.loading);
    $.ajax({
      url: url,
      method: 'POST',
      data: {
        item: {
          name: default_name,
          url: location.pathname,
          model: model
        }
      },
      success: function(data) {
        el.find('.dropdown-menu').html(html);
        el.addClass('active');
        el.find('.dropdown-menu').addClass('active');
        el.find('.material-icons').html(bookmark_icon);
        el.find('.bookmark-notice').text(data['notice']);
        el.find('.bookmark-name').val(default_name);
        bookmark_id = data['bookmark_id'];
        loading = false;
      },
      error: function() {
        alert('Error');
      }
    });
  };

  Gws_Bookmark.update = function() {
    loading = true;
    var html, new_name, uri;
    new_name = el.find('.bookmark-name').val() || default_name;
    uri = url + '/' + bookmark_id;
    html = el.find('.dropdown-menu').html();
    el.find('.dropdown-menu').html(SS.loading);
    el.addClass('active');
    el.find('.dropdown-menu').addClass('active');
    $.ajax({
      url: uri,
      method: 'POST',
      data: {
        _method: 'patch',
        item: {
          name: new_name,
          url: location.pathname,
          model: model
        }
      },
      success: function(data) {
        el.find('.dropdown-menu').html(html);
        el.removeClass('active');
        el.find('.dropdown-menu').removeClass('active');
        el.find('.material-icons').html(bookmark_icon);
        el.find('.bookmark-notice').text(data['notice']);
        el.find('.bookmark-name').val(new_name);
        bookmark_id = data['bookmark_id'];
        loading = false;
      },
      error: function() {
        alert('Error');
      }
    });
  };

  Gws_Bookmark["delete"] = function() {
    if (!bookmark_id) {
      return false;
    }
    loading = true;
    var html, uri;
    uri = url + '/' + bookmark_id;
    html = el.find('.dropdown-menu').html();
    el.find('.dropdown-menu').html(SS.loading);
    el.addClass('active');
    el.find('.dropdown-menu').addClass('active');
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
        el.find('.dropdown-menu').html(html);
        el.removeClass('active');
        el.find('.dropdown-menu').removeClass('active');
        el.find('.material-icons').html(unbookmark_icon);
        el.find('.bookmark-notice').text('');
        el.find('.bookmark-name').text(default_name);
        bookmark_id = null;
        loading = false;
      },
      error: function() {
        alert('Error');
      }
    });
  };

  return Gws_Bookmark;

})();
