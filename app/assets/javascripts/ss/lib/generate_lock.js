SS_GenerateLock = function(el) {
  this.$el = $(el);
  this.render();
};

SS_GenerateLock.prototype.render = function() {
  var _this = this;
  this.$el.find(".btn-generate-lock").on("click", function() {
    _this.lock($(this))
  });
};

SS_GenerateLock.prototype.lock = function($btn) {
  var _this = this;
  $.ajax({
    url: $btn.data('href'),
    method: 'post',
    data: {
      _method: 'PUT',
      generate_lock: this.$el.find("#generate_lock").val()
    },
    beforeSend: function() {
      $btn.prop("disabled", true);
      _this.$el.find('dd').html(SS.loading);
    },
    success: function(data) {
      $btn.prop("disabled", false);
      _this.$el.find('dd').text(data['generate_lock_until']);
    }
  });
};
