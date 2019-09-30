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

  this.$el.find('button[name=punch]').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var action = $(this).data('action');
    var confirm = $(this).data('confirm');
    _this.onPunchClicked(action, confirm);
  });

  this.$el.find('button[name=edit]').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var action = $(this).data('action');
    var confirm = $(this).data('confirm');
    _this.onEditClicked(action, confirm);
  });

  this.$el.find('.reason-tooltip').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.hideToolbar();
    _this.hideTooltip();
    $(this).find('.reason').show();
  });

  this.$el.find('.leave-file-tooltip').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var href = $(this).attr("data-href");
    $.colorbox({ href: href });
  });

  this.$el.find('select[name=year_month]').on('change', function() {
    var val = $(this).val();
    if (! val) {
      return;
    }
    location.href = _this.options.indexUrl.replace(':year_month', val);
  });

  this.$toolbar.find(".punch").on("click", function() {
    _this.onPunchClicked($(this).attr("href"), $(this).data("confirmation"), $(this).data("type"));
    return false;
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

  $(document).on('click', this.el + ' .time-card .working-time-edit', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickWorkingTime($(this));
  });

  $(document).on('click', function() {
    _this.hideToolbar();
    _this.hideTooltip();
  });
};

Gws_Attendance.prototype.onPunchClicked = function(action, message) {
  if (! action) {
    return;
  }

  if (message) {
    if (! confirm(message)) {
      return;
    }
  }

  var token = $('meta[name="csrf-token"]').attr('content');

  $form = $('<form/>', { action: action, method: 'post' });
  $form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
  $('body').append($form);
  $form.submit();
};

Gws_Attendance.prototype.onEditClicked = function(action, message) {
  if (!action) {
    return
  }

  if (message) {
    if (!confirm(message)) {
      return;
    }
  }

  $a = $('<a />', { href: action });
  $a.colorbox({ open: true, width: '90%' });
};

Gws_Attendance.prototype.hideToolbar = function() {
  this.$toolbar.hide();
};

Gws_Attendance.prototype.hideTooltip = function() {
  this.$el.find('.reason-tooltip .reason').hide();
};

Gws_Attendance.prototype.onClickTime = function($cell) {
  this.onClickCell($cell, this.options.timeUrl);
};

Gws_Attendance.prototype.onClickMemo = function($cell) {
  this.onClickCell($cell, this.options.memoUrl);
};
Gws_Attendance.prototype.onClickWorkingTime = function($cell) {
  this.onClickCell($cell, this.options.workingTimeUrl);
};

Gws_Attendance.prototype.setFocus = function($cell) {
  this.$el.find('.time-card .time').removeClass('focus');
  this.$el.find('.time-card .memo').removeClass('focus');
  this.$el.find('.time-card .working_time').removeClass('focus');
  $cell.addClass('focus');
};

Gws_Attendance.prototype.isCellToday = function($cell) {
  return $cell.closest('tr').hasClass('current');
};

Gws_Attendance.prototype.onClickCell = function($cell, urlTemplate) {
  this.hideTooltip();

  if (! $cell.data('day')) {
    return;
  }

  this.setFocus($cell);

  if (!this.options.editable && !this.isCellToday($cell)) {
    this.$toolbar.hide();
    return;
  }

  var day = $cell.data('day');
  var type = $cell.data('type');
  var mode = $cell.data('mode');

  var punchable = this.isCellToday($cell);
  var editable = this.options.editable;

  if (type === "memo") {
    if (this.isCellToday($cell)) {
      editable = true;
    }
  }

  if (type === "working_time") {
    if (this.isCellToday($cell)) {
      editable = true;
    }
  }

  var showsToolbar = false;
  if (mode === "punch" && punchable && this.options.punchUrl) {
    var url = this.options.punchUrl;
    url = url.replace(':type', type);

    this.$toolbar.find('.edit').hide();
    this.$toolbar.find('.punch').attr('href', url).show();
    showsToolbar = true;
  }

  if (mode === "edit" && editable) {
    var url = urlTemplate;
    url = url.replace(':day', day);
    url = url.replace(':type', type);

    this.$toolbar.find('.punch').hide();
    this.$toolbar.find('.edit').attr('href', url).show();
    showsToolbar = true;
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
