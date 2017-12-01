// Readable Setting UI
function Gws_ReadableSetting(selector) {
  this.el = $(selector);
}

Gws_ReadableSetting.prototype.render = function() {
  var _this = this;
  this.el.find('.buttons input').change(function() {
    var val = $(this).val();
    if (val == 'select') {
      _this.showSelectForm();
    } else {
      _this.hideSelectForm();
    }
  });

  var val = this.el.find('.buttons input:checked').val();
  if (val == 'select') {
    this.el.find('.gws-addon-readable-setting-select').show();
  } else {
    this.el.find('.gws-addon-readable-setting-select').hide();
  }
};

Gws_ReadableSetting.prototype.showSelectForm = function() {
  this.el.find('.gws-addon-readable-setting-select').slideDown("fast");
}

Gws_ReadableSetting.prototype.hideSelectForm = function() {
  this.el.find('.gws-addon-readable-setting-select').slideUp("fast");
}
