Gws_Affair2_Attendance = function (el, ref) {
  this.$el = $(el);
  this.ref = ref;
  this.$toolbar = this.$el.find('.cell-toolbar');
  this.renderCommon();
};

Gws_Affair2_Attendance.prototype.renderCommon = function() {
  var self = this;

  // reason tooltips events
  this.$el.find('.reason-tooltip').on('click', function() {
    self.hideToolbar();
    self.hideTooltip();
    $(this).find('.reason').show();
    return false;
  });

  $(document).on('click', function() {
    self.hideToolbar();
    self.hideTooltip();
  });
};

Gws_Affair2_Attendance.prototype.renderToday = function() {
  var self = this;

  // today events
  this.$el.find('.today .edit').on("click", function(){
    var href = $(this).data("url");
    $.colorbox({
      fixed: true,
      open: true,
      href: href,
      width: "90%",
      onComplete: function() {
        $("#cboxLoadedContent").find('[name="ref"]').val(self.ref);
      }
    });
  });
  this.$el.find('.today .punch').on("click", function () {
    var message = $(this).data("confirm");
    if (message) {
      if (! confirm(message)) {
        return false;
      }
    }

    var action = $(this).data("url");
    var token = $('meta[name="csrf-token"]').attr('content');

    $form = $('<form/>', { action: action, method: 'post' });
    $form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
    $form.append($("<input/>", { name: "ref", value: self.ref, type: "hidden" }));

    $('body').append($form);
    $form.submit();

    return false;
  });
};

Gws_Affair2_Attendance.prototype.renderMonthly = function() {
  var self = this;

  // toolbar events
  this.$el.find('.cell-toolbar .edit').colorbox({
    fixed: true,
    width: "90%",
    onComplete: function() {
      $("#cboxLoadedContent").find('[name="ref"]').val(self.ref);
    }
  });
  this.$el.find('.cell-toolbar .punch').on("click", function () {
    var message = $(this).data("confirm");
    if (message) {
      if (! confirm(message)) {
        return false;
      }
    }

    var action = $(this).attr("href");
    var token = $('meta[name="csrf-token"]').attr('content');

    $form = $('<form/>', { action: action, method: 'post' });
    $form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
    $form.append($("<input/>", { name: "ref", value: self.ref, type: "hidden" }));

    $('body').append($form);
    $form.submit();

    return false;
  });

  // cell events
  this.$el.find('[data-mode="punch"]').on("click", function() {
    self.onPunch($(this));
    return false;
  });
  this.$el.find('[data-mode="edit"]').on("click", function() {
    self.onEdit($(this));
    return false;
  });
  this.$el.find('[data-mode="none"]').on("click", function() {
    self.hideToolbar();
    self.hideTooltip();
    self.setFocus($(this));
    return false;
  });

  // edit overtime_records events
  this.$el.find('.edit-overtime-records').colorbox({
    fixed: true,
    width: "90%",
    onComplete: function() {
      $("#cboxLoadedContent").find('[name="ref"]').val(self.ref);
    }
  });

  // edit leave_records events
  this.$el.find('.edit-leave-records').colorbox({
    fixed: true,
    width: "90%",
    onComplete: function() {
      $("#cboxLoadedContent").find('[name="ref"]').val(self.ref);
    }
  });

  // regular import events
  this.$el.find('.regular-import').colorbox({
    fixed: true,
    width: "90%",
    onComplete: function() {
      $("#cboxLoadedContent").find('[name="ref"]').val(self.ref);
    }
  });
};

/*
Gws_Affair2_Attendance.prototype.onPunchClicked = function(action, message) {
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
*/

/*
Gws_Affair2_Attendance.prototype.onEditClicked = function(action, message) {
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
*/

Gws_Affair2_Attendance.prototype.hideToolbar = function() {
  this.$toolbar.hide();
};

Gws_Affair2_Attendance.prototype.hideTooltip = function() {
  this.$el.find('.reason-tooltip .reason').hide();
};

Gws_Affair2_Attendance.prototype.setFocus = function($cell) {
  this.$el.find('.time-card .time').removeClass('focus');
  this.$el.find('.time-card .memo').removeClass('focus');
  this.$el.find('.time-card .working_time').removeClass('focus');
  $cell.addClass('focus');
};

/*
Gws_Affair2_Attendance.prototype.isCellToday = function($cell) {
  return $cell.closest('tr').hasClass('current');
};
*/

Gws_Affair2_Attendance.prototype.onPunch = function($cell) {
  this.hideTooltip();
  this.setFocus($cell);

  this.$toolbar.find('.punch').attr('href', $cell.data("url")).show();
  this.$toolbar.find('.edit').hide();

  var offset = $cell.offset();
  if ($cell.hasClass('top')) {
    offset.top -= this.$toolbar.outerHeight();
  } else {
    offset.top += $cell.outerHeight();
  }

  this.$toolbar.show();
  this.$toolbar.offset(offset);
};

Gws_Affair2_Attendance.prototype.onEdit = function($cell) {
  this.hideTooltip();
  this.setFocus($cell);

  /*
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
  */

  this.$toolbar.find('.punch').hide();
  this.$toolbar.find('.edit').attr('href', $cell.data("url")).show();

  var offset = $cell.offset();
  if ($cell.hasClass('top')) {
    offset.top -= this.$toolbar.outerHeight();
  } else {
    offset.top += $cell.outerHeight();
  }

  this.$toolbar.show();
  this.$toolbar.offset(offset);
};
