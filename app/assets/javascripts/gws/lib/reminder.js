this.Gws_Reminder = (function () {
  function Gws_Reminder() {
  }

  Gws_Reminder.renderList = function (opts) {
    var el;
    if (opts == null) {
      opts = {};
    }
    el = $(opts['el'] || document);
    el.find('.list-item').each(function () {
      var $a = $('<a />', { class: "restore", href: "#", style: "display: none;" })
        .text(i18next.t("gws/reminder.links.restore_reminder"));
      return $(this).find('.links').prepend($a);
    });
    el.find('.list-item.deleted').each(function () {
      $(this).find('.check, .meta, .delete, .updated, .more-btn').hide();
      $(this).find('.dropdown-menu').removeClass('active');
      $(this).find('.restore').show();
      return $(this).find('.notification').hide();
    });
    el.find('.list-item .delete').on("click", function () {
      var item;
      item = $(this).closest('.list-item');
      $.ajax({
        url: opts['url'],
        method: 'post',
        data: {
          _method: 'delete',
          id: item.data('id'),
          item_id: item.data('item_id'),
          item_model: item.data('model'),
          item_name: item.data('name'),
          date: item.data('date')
        },
        success: function (_data) {
          item.toggleClass('gws-list-item--deleted').find('.check, .meta, .delete, .updated, .more-btn').hide();
          item.find('.dropdown-menu').removeClass('active');
          item.find('.restore').show();
          item.find('.notification').hide();
          return false;
        },
        error: function (_data) {
          return alert('Error');
        }
      });
      return false;
    });
    return el.find('.list-item .restore').on("click", function () {
      var item;
      item = $(this).closest('.list-item');
      $.ajax({
        url: opts['restore_url'],
        method: 'post',
        data: {
          id: item.data('id'),
          item_id: item.data('item_id'),
          item_model: item.data('model'),
          item_name: item.data('name'),
          date: item.data('date')
        },
        success: function (_data) {
          item.toggleClass('gws-list-item--deleted').find('.check, .meta, .delete, .more-btn').show();
          item.find('.restore').hide();
          if (item.find('.notification')[0]) {
            item.find('.notification')[0].selectedIndex = 0;
          }
          item.find('.notification').show();
          return false;
        },
        error: function (_data) {
          return alert('Error');
        }
      });
      return false;
    });
  };

  return Gws_Reminder;

})();
