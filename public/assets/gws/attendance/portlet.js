Gws_Attendance_Portlet = function (el, options) {
  // this.el = el;
  this.$el = $(el);
  // this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  // this.now = new Date(options.now);
  this.render();
};

Gws_Attendance_Portlet.prototype.render = function() {
  var _this = this;

  this.$el.find('button[name=punch]').on('click', function() {
    _this.punch($(this), $(this).closest('tr').data('field-name'));
  });

  this.$el.find('button[name=edit]').on('click', function() {
    _this.edit($(this), $(this).closest('tr').data('field-name'));
  });
};

Gws_Attendance_Portlet.prototype.punch = function($button, fieldName) {
  $button.attr('disabled', 'disabled');
  if (! confirm(this.options.confirmMessage)) {
    $button.removeAttr('disabled');
    return;
  }

  var url = this.options.punchUrl.replace(':TYPE', fieldName);
  var _this = this;
  $.ajax({
    url: url,
    method: 'POST',
    data: { ref: this.options.ref },
    dataType: 'json',
    success: function(data) {
      alert(_this.options.successMessage);
      location.reload();
    },
    error: function(xhr, status, error) {
      alert(xhr.responseJSON.join("\n"));
    },
    complete: function() {
      $button.removeAttr('disabled');
    }
  });
};

Gws_Attendance_Portlet.prototype.edit = function($button, fieldName) {
  $button.attr('disabled', 'disabled');

  var url = this.options.editUrl.replace(':TYPE', fieldName);
  $a = $('<a/>', { href: url });
  $a.colorbox({
    open: true,
    width: '90%',
    onClosed: function() { $button.removeAttr('disabled'); }
  });
};
