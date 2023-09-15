function Gws_SearchForm(el) {
  this.$el = $(el);
  this.render();
}

Gws_SearchForm.render = function() {
  $(document).find(".gws-search").each(function() {
    new Gws_SearchForm(this)
  });
};

Gws_SearchForm.prototype.render = function() {
  var self = this;

  self.$el.find('[name="target"]').on("change", function(){
    var target = $(this).val();
    self.toggleTarget(target);
  });

  var target = Cookies.get("ss-gws-search");
  if (!target || !self.$el.find('[data-target="' + target + '"]').length) {
    target = self.$el.find('[data-target]:first').attr("data-target");
    Cookies.set("ss-gws-search", target, {
      expires: 7,
      path: '/'
    });
  }
  self.$el.find('[name="target"][value="' + target + '"]').prop("checked", true);
  self.toggleTarget(target);
};

Gws_SearchForm.prototype.toggleTarget = function(target) {
  var self = this;

  var keyword = self.$el.find(".keyword:visible").val();
  self.$el.find(".keyword").val(keyword);

  self.$el.find('[data-target]').hide();
  self.$el.find('[data-target="' + target + '"]').show();

  Cookies.set("ss-gws-search", target, {
    expires: 7,
    path: '/'
  });
}

Gws_SearchForm.renderExternalSearch = function() {
  $("a[data-external-search-url]").on("click", function() {
    var href = $(this).attr("data-external-search-url");
    var keyword = $('.list-head-search-full [name="s[keyword]"]').val();
    href = href.replace('KEYWORD', keyword);
    $(this).attr("href", href);
    return true;
  });

  // Search for KEYWORD using ...
  var showKeyword = function() {
    var keyword = $('.list-head-search-full [name="s[keyword]"]').val();
    $(".external-search .search-for-keyword").each(function(){
      if (keyword) {
        $(this).find(".with-keyword").show();
        $(this).find(".default").hide();

        $(this).find(".with-keyword .keyword").text(keyword);
      } else {
        $(this).find(".with-keyword").hide();
        $(this).find(".default").show();
      }
    });
  }
  $('.list-head-search-full [name="s[keyword]"]').on("keyup", showKeyword);
  showKeyword();
};
