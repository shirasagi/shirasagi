// Readable Setting UI
function Cms_ReadableSetting(selector) {
  this.el = $(selector);
}

Cms_ReadableSetting.prototype.render = function() {
  var _this = this;
  this.el.find('.buttons input').on("change", function() {
    var val = $(this).val();
    if (val == 'select') {
      _this.showSelectForm();
    } else {
      _this.hideSelectForm();
    }
  });

  var val = this.el.find('.buttons input:checked').val();
  if (val == 'select') {
    this.el.find('.cms-addon-readable-setting-select').show();
  } else {
    this.el.find('.cms-addon-readable-setting-select').hide();
  }
};

Cms_ReadableSetting.prototype.showSelectForm = function() {
  this.el.find('.cms-addon-readable-setting-select').slideDown("fast");
}

Cms_ReadableSetting.prototype.hideSelectForm = function() {
  this.el.find('.cms-addon-readable-setting-select').slideUp("fast");
}
