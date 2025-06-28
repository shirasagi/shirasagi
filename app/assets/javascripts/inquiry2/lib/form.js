Inquiry2_Form = function (options) {
  this.options = options;
  this.render();
};

Inquiry2_Form.instance = null;

Inquiry2_Form.render = function(options) {
  if (Inquiry2_Form.instance) {
    return;
  }

  Inquiry2_Form.instance = new Inquiry2_Form(options);
};

Inquiry2_Form.prototype.render = function() {
  $('.inquiry2-form input:not([type="submit"], [type="button"], [type="reset"])').on('keypress', function (ev) {
    if ((ev.which && ev.which === SS.KEY_ENTER) || (ev.keyCode && ev.keyCode === SS.KEY_ENTER)) {
      return false;
    } else {
      return true;
    }
  });

  var _this = this;
  $(document).on('change', '.form-select input[type="radio"]', function() {
    return _this.changeForm();
  });

  if ($('.form-select').length > 0) {
    this.changeForm();
  }
};

Inquiry2_Form.prototype.collectSelectFormValues = function() {
  var selector;
  if (this.options.confirm) {
    selector = 'input[type="hidden"]';
  } else {
    selector = 'input[type="radio"]:checked';
  }

  var values = [];
  $('.form-select ' + selector).each(function() {
    var val = $(this).val();
    if (values.indexOf(val) < 0) {
      values.push(val);
    }
  });
  return values;
};

Inquiry2_Form.prototype.intersect = function(arr1, arr2) {
  return arr1.filter(function(el) {
    return arr2.indexOf(el) !== -1
  });
};

Inquiry2_Form.prototype.changeForm = function() {
  var _this = this;
  var checkedValues = this.collectSelectFormValues();

  $('.select-form-target').each(function() {
    if (_this.intersect(checkedValues, $(this).data('select-form')).length > 0) {
      // append required label if absent
      if ($(this).find('span.required').length === 0) {
        var span = $("<span/>").attr('class', 'required').text(_this.options.requiredLabel);
        if (_this.options.confirm) {
          span.appendTo($(this).children('dt'));
        } else {
          span.appendTo($(this).children('legend'));
        }
      }
    } else {
      // remove required label
      $(this).find('span.required').remove();
    }
  });
};
