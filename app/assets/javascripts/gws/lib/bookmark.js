this.Gws_Bookmark = (function() {
  function Gws_Bookmark() {}

  Gws_Bookmark.render = function(name, url, model) {
    var el, bookmark_icon, unbookmark_icon;
    el = $('.gws-bookmark');
    bookmark_icon = "&#xE866;";
    unbookmark_icon = "&#xE867;";
    el.click(function(e) {
      if (el.find('img[src="/assets/img/loading.gif"]').length > 0) {
        return false;
      } else if ($(e.target).hasClass('update')) {
        Gws_Bookmark.update(el, name, url, model, bookmark_icon);
      } else if ($(e.target).hasClass('delete')) {
        Gws_Bookmark["delete"](el, name, url, model, unbookmark_icon);
      } else if (el.find('.bookmark-id').val()) {
        el.addClass('active');
        el.find('.dropdown-menu').addClass('active');
      } else {
        Gws_Bookmark.create(el, name, url, model, bookmark_icon);
      }
    });
  };

  Gws_Bookmark.create = function(el, name, url, model, icon) {
    var html;
    html = el.html();
    el.find('.dropdown-menu').html(SS.loading);
    $.ajax({
      url: url,
      method: 'POST',
      data: {
        item: {
          name: name,
          url: location.pathname,
          model: model
        }
      },
      success: function(data) {
        el.html(html);
        el.addClass('active');
        el.find('.dropdown-menu').addClass('active');
        el.find('.bookmark-notice').text(data['notice']);
        el.find('.bookmark-id').val(data['bookmark_id']);
        el.find('.bookmark-name').val(name);
        el.find('.material-icons').html(icon);
      },
      error: function() {
        alert('Error');
      }
    });
  };

  Gws_Bookmark.update = function(el, name, url, model, icon) {
    var html, new_name, uri;
    new_name = el.find('.bookmark-name').val() || name;
    uri = url + '/' + el.find('.bookmark-id').val();
    html = el.html();
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
        el.html(html);
        el.removeClass('active');
        el.find('.dropdown-menu').removeClass('active');
        el.find('.bookmark-notice').text(data['notice']);
        el.find('.bookmark-name').val(data['name']);
        el.find('.material-icons').html(icon);
      },
      error: function() {
        alert('Error');
      }
    });
  };

  Gws_Bookmark["delete"] = function(el, name, url, model, icon) {
    if (!el.find('.bookmark-id').val()) {
      return false;
    }
    var html, uri;
    uri = url + '/' + el.find('.bookmark-id').val();
    html = el.html();
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
        el.html(html);
        el.removeClass('active');
        el.find('.dropdown-menu').removeClass('active');
        el.find('.bookmark-notice').text('');
        el.find('.bookmark-id').val('');
        el.find('.bookmark-name').val(name);
        el.find('.material-icons').html(icon);
      },
      error: function() {
        alert('Error');
      }
    });
  };

  return Gws_Bookmark;

})();
