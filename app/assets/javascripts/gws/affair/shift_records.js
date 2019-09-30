Gws_Affair_ShiftRecords = function (el, options) {
  this.el = el;
  this.$el = $(el);
  this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  this.render();
};

Gws_Affair_ShiftRecords.prototype.render = function() {
  var _this = this;

  $(document).on('click', this.el + ' .shift-record', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.onClickCell($(this));
  });

  $(this.el).find(".wrap-table").scroll(function () {
    _this.$toolbar.hide();
  });

  _this.$toolbar.hide();
};

Gws_Affair_ShiftRecords.prototype.setFocus = function($cell) {
  this.$el.find('.shift-record').removeClass('focus');
  $cell.addClass('focus');
};

Gws_Affair_ShiftRecords.prototype.onClickCell = function($cell, urlTemplate) {
  this.setFocus($cell);

  var day = $cell.data('day');
  var user = $cell.data('user');

  var showsToolbar = false;
  var editable = this.options.editable;
  if (editable) {
    var url = this.options.shiftRecordUrl;
    url = url.replace(':day', day);
    url = url.replace(':user', user);

    showsToolbar = true;
    this.$toolbar.find('.edit').attr('href', url).show();
  }

  if (! showsToolbar) {
    this.$toolbar.hide();
    return;
  }

  var offset = $cell.offset();
  if ($cell.hasClass('top')) {
    offset.top -= this.$toolbar.outerHeight();
  } else {
    offset.top += $cell.outerHeight();
  }

  // call `show` and then call `offset`. order is important
  this.$toolbar.show();
  this.$toolbar.offset(offset);
};
