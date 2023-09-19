Cms_Move = function (el, url, keyword, confirm) {
  this.$el = $(el);
  this.url = url;
  this.keyword = keyword;
  this.confirm = confirm;
  this.render();
}

Cms_Move.prototype.render = function() {
  var self = this;
  var $result = self.$el.find(".result");

  if (self.confirm) {
    data = {
      s: {
        keyword: self.keyword,
        option: "string"
      }
    };
    $result.closest(".see").show();
    $.ajax({
      type: "GET",
      data: data,
      url: self.url + "?" + $.param(data),
      beforeSend: function () {
        $result.html(SS.loading);
      },
      success: function (data) {
        $result.html(data);
        $result.find("th input").remove();
        $result.find("input[name='page_ids[]']").remove();
        $result.find("input[name='part_ids[]']").remove();
        $result.find("input[name='layout_ids[]']").remove();
      },
      error: function (data, status) {
        alert(["== Error(Move) =="].concat(data.responseJSON).join("\n"));
      }
    });
  }
};
