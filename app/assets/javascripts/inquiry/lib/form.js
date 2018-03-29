Inquiry_Form = function (options) {
  this.options = options;
  this.render();
};

Inquiry_Form.instance = null;

Inquiry_Form.render = function(options) {
  if (Inquiry_Form.instance) {
    return;
  }

  Inquiry_Form.instance = new Inquiry_Form(options);
};

Inquiry_Form.prototype.render = function() {
  $('.inquiry-form input').on('keypress', function (ev) {
    if ((ev.which && ev.which === 13) || (ev.keyCode && ev.keyCode === 13)) {
      return false;
    } else {
      return true;
    }
  });

  var _this = this;
  $('.form-select').each(function() {
    return _this.changeForm($(this));
  });
  $(document).on('change', '.form-select', function() {
    return _this.changeForm($(this));
  });
};

Inquiry_Form.prototype.changeForm = function(self) {
  var _this = this;

  self.find('input').each(function () {
    if ($(this).prop('checked') || _this.options.confirm) {
      var value = $(this).val();
      $(".column").each(function () {
        $(this).find('span.required').remove();
        var span;
        if ($(this).hasClass(value) && $(this).children('span').text() === '') {
          span = $("<span/>").attr('class', 'required').text(_this.options.requiredLabel);
          span.appendTo($(this).children('dt'));
        }
      });
    }
  });
};
