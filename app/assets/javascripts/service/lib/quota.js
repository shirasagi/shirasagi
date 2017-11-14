function Service_Quota(selector) {
  this.el = $(selector);
  this.reloadButton = this.el.find('.reload-quota');
}

Service_Quota.prototype.render = function() {
  var _this = this;
  this.reloadButton.click(function() {
    _this.reloadQuota();
  });
};

Service_Quota.prototype.reloadQuota = function() {
  var _this = this;
  $.ajax({
    url: _this.reloadButton.data('href'),
    method: 'post',
    data: {
      _method: 'PUT'
    },
    beforeSend: function() {
      _this.reloadButton.prop("disabled", true);
      _this.el.find('.base-quota-used').text('...');
      _this.el.find('.cms-quota-used').text('...');
      _this.el.find('.gws-quota-used').text('...');
      _this.el.find('.webmail-quota-used').text('...');
    },
    success: function(data) {
      _this.reloadButton.prop("disabled", false);
      _this.el.find('.base-quota-used').text(data.base_quota_used_size);
      _this.el.find('.cms-quota-used').text(data.cms_quota_used_size);
      _this.el.find('.gws-quota-used').text(data.gws_quota_used_size);
      _this.el.find('.webmail-quota-used').text(data.webmail_quota_used_size);
    }
  });
};
