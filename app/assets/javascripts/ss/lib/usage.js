SS_Usage = function(el) {
  this.$el = $(el);
  this.render();
};

SS_Usage.selectors = [
  '.usage-node-count',
  '.usage-page-count',
  '.usage-file-count',
  '.usage-db-size',
  '.usage-group-count',
  '.usage-user-count',
  '.usage-calculated-at'
];

SS_Usage.prototype.render = function() {
  var _this = this;
  this.$el.find(".btn-reload-usages").on("click", function() {
    _this.reload($(this))
  });
};

SS_Usage.prototype.reload = function($btn) {
  var _this = this;
  $.ajax({
    url: $btn.data('href'),
    method: 'post',
    data: {
      _method: 'PUT'
    },
    beforeSend: function() {
      $btn.prop("disabled", true);

      for (var i = 0; i < SS_Usage.selectors.length; i++) {
        var selector = SS_Usage.selectors[i];
        var el = _this.$el.find(selector);
        if (el[0]) {
          el.html(SS.loading);
        }
      }
    },
    success: function(data) {
      $btn.prop("disabled", false);

      for (var i = 0; i < SS_Usage.selectors.length; i++) {
        var selector = SS_Usage.selectors[i];
        var el = _this.$el.find(selector);
        if (el[0]) {
          var valName = selector.replace(".", "").replace(/-/g, "_") + "_html";
          if (data[valName]) {
            el.html(data[valName]);
          } else {
            el.html("-");
          }
        }
      }
    },
    error: function(xhr, status, error) {
      for (var i = 0; i < SS_Usage.selectors.length; i++) {
        var selector = SS_Usage.selectors[i];
        var el = _this.$el.find(selector);
        el.html(error);
      }
    }
  });
};
