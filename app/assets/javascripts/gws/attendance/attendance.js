Gws_Attendance = function (el, options) {
  this.el = el;
  this.$el = $(el);
  this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  this.now = new Date(options.now);
  this.render();
};

Gws_Attendance.prototype.render = function() {
  var _this = this;

  this.$el.find('button').on('click', function() {
    var action = $(this).data('action');
    _this.postPunchAction(action);
  });

  $(document).on('click', this.el + ' .time-card .time', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickTime($(this));
  });

  $(document).on('click', this.el + ' .time-card .memo', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickMemo($(this));
  });

  $(document).on('click', function() {
    _this.hideToolbar();
  });
};

Gws_Attendance.prototype.postPunchAction = function(action) {
  var token = $('meta[name="csrf-token"]').attr('content');

  $form = $('<form/>', { action: action, method: 'post' });
  $form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
  $('body').append($form);
  $form.submit();
};

Gws_Attendance.prototype.hideToolbar = function() {
  this.$toolbar.find('.reason').html('');
  this.$toolbar.find('.reason').hide();
  this.$toolbar.hide();
};

Gws_Attendance.prototype.onClickTime = function($cell) {
  this.onClickCell($cell, this.options.timeUrl);
};

Gws_Attendance.prototype.onClickMemo = function($cell) {
  this.onClickCell($cell, this.options.memoUrl);
};

Gws_Attendance.prototype.setFocus = function($cell) {
  this.$el.find('.time-card .time').removeClass('focus');
  this.$el.find('.time-card .memo').removeClass('focus');
  $cell.addClass('focus');
};

Gws_Attendance.prototype.setReason = function($cell) {
  this.$toolbar.find('.reason').html('');

  var reasonHtml = $cell.find('.reason-tooltip .reason').html();
  if (reasonHtml) {
    this.$toolbar.find('.reason').append(reasonHtml);
    this.$toolbar.find('.reason').show();
    return true;
  } else {
    this.$toolbar.find('.reason').hide();
    return false;
  }
};

Gws_Attendance.prototype.isCellToday = function($cell) {
  return $cell.closest('tr').hasClass('current');
};

Gws_Attendance.prototype.onClickCell = function($cell, urlTemplate) {
  this.setFocus($cell);

  if (! this.setReason($cell)) {
    if (!this.options.editable && !this.isCellToday($cell)) {
      this.$toolbar.hide();
      return;
    }
  }

  var url = urlTemplate;
  url = url.replace(':day', $cell.data('day'));
  url = url.replace(':type', $cell.data('type'));
  this.$toolbar.find('.edit').attr('href', url);
  if (this.options.editable || this.isCellToday($cell)) {
    this.$toolbar.find('.edit').show();
  } else {
    this.$toolbar.find('.edit').hide();
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
