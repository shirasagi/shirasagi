Gws_Attendance = function (el, options) {
  this.el = el;
  this.$el = $(el);
  this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
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

Gws_Attendance.prototype.onClickCell = function($cell, urlTemplate) {
  this.$el.find('.time-card .time').removeClass('focus');
  this.$el.find('.time-card .memo').removeClass('focus');
  $cell.addClass('focus');

  var url = urlTemplate;
  url = url.replace(':day', $cell.data('day'));
  url = url.replace(':type', $cell.data('type'));

  var reasonHtml = $cell.find('.reason-tooltip .reason').html();
  this.$toolbar.find('.reason').html('');
  if (reasonHtml) {
    this.$toolbar.find('.reason').append(reasonHtml);
    this.$toolbar.find('.reason').show();
  } else {
    this.$toolbar.find('.reason').hide();
  }

  var offset = $cell.offset();
  if ($cell.hasClass('top')) {
    offset.top -= this.$toolbar.outerHeight();
  } else {
    offset.top += $cell.outerHeight();
  }

  this.$toolbar.find('.edit').attr('href', url);
  // call `show` and then call `offset`. order is important
  this.$toolbar.show();
  this.$toolbar.offset(offset);
};
