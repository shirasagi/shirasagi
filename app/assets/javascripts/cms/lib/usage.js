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
  var url = $btn.data('href');

  if (url.endsWith(".json")) {
    this.reloadByJson($btn);
  } else {
    // HTML
    this.reloadByHtml($btn);
  }
};

Cms_Usage.prototype.reloadByHtml = function($btn) {
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

Cms_Usage.prototype.reloadByJson = function($btn) {
  var _this = this;
  $.ajax({
    url: $btn.data('href'),
    method: 'post',
    data: {
      _method: 'PUT'
    },
    beforeSend: function() {
      $btn.prop("disabled", true);
      _this.$el.find('.cms-usage-node-count').html(SS.loading);
      _this.$el.find('.cms-usage-page-count').html(SS.loading);
      _this.$el.find('.cms-usage-file-count').html(SS.loading);
      _this.$el.find('.cms-usage-db-size').html(SS.loading);
      _this.$el.find('.cms-usage-group-count').html(SS.loading);
      _this.$el.find('.cms-usage-user-count').html(SS.loading);
      _this.$el.find('.cms-usage-calculated-at').html(SS.loading);
    },
    success: function(data) {
      $btn.prop("disabled", false);
      _this.$el.find('.cms-usage-node-count').html(data.usage_node_count_html);
      _this.$el.find('.cms-usage-page-count').html(data.usage_page_count_html);
      _this.$el.find('.cms-usage-file-count').html(data.usage_file_count_html);
      _this.$el.find('.cms-usage-db-size').html(data.usage_db_size_html);
      _this.$el.find('.cms-usage-group-count').html(data.usage_group_count_html);
      _this.$el.find('.cms-usage-user-count').html(data.usage_user_count_html);
      _this.$el.find('.cms-usage-calculated-at').html(data.usage_calculated_at_html);
    }
  });
};
