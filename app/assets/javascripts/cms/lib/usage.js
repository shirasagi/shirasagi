Cms_Usage = function(el) {
  this.$el = $(el);
  this.render();
};

Cms_Usage.prototype.render = function() {
  var _this = this;
  this.$el.find(".btn-reload-cms-usages").on("click", function() {
    _this.reload($(this))
  });
};

Cms_Usage.prototype.reload = function($btn) {
  var _this = this;
  $.ajax({
    url: $btn.data('href'),
    method: 'post',
    data: {
      _method: 'PUT'
    },
    beforeSend: function() {
      $btn.prop("disabled", true);
      _this.$el.find('.cms-usages').html(SS.loading);
    },
    success: function(data) {
      $btn.prop("disabled", false);
      _this.$el.find('.cms-usages').html($(data).find('.cms-usages').html());
    }
  });
};
