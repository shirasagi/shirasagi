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


function FolderMove(el, url, keyword, confirm) {
  this.$el = $(el);
  this.url = url;
  this.keyword = keyword;
  this.confirm = confirm;
  this.render();
}

FolderMove.prototype.render = function() {
  if (this.confirm) {
    var data = this.getData();
    this.sendAjaxRequest(data);
  }
};

FolderMove.prototype.getData = function() {
  return {
    s: {
      keyword: this.keyword,
      option: "string"
    }
  };
};

FolderMove.prototype.sendAjaxRequest = function(data) {
  var self = this;
  $.ajax({
    type: "GET",
    data: data,
    url: self.url + "?" + $.param(data),
    success: function(data) {
      $("#cboxOverlay").show();
      self.openDialog(data);
    },
    error: function(data, status) {
      alert(["== Error(Move) =="].concat(data.responseJSON).join("\n"));
    }
  });
};

FolderMove.prototype.openDialog = function(data) {
  var $dialog = $("#cms-dialog").dialog({
    autoOpen: false,
    width: 800,
    modal: true,
    create: function() {
      $(this).closest(".ui-dialog").css({
        "z-index": 9999, 
        "position": "fixed",
        "height": "auto"
      });
    },
    open: function() {
      $(this).parent().find('.ui-dialog-titlebar').css({
        "background": "white",
        "border": "none"
      });
    },
    close: function() {
      window.history.back();
    }
  });
  var $result = $dialog.find(".see")
  this.setupDialogContent($result, data);
  $dialog.dialog("open");
};

FolderMove.prototype.setupDialogContent = function($dialog, data) {
  $dialog.html(data);
  $dialog.find("th input").remove();
  $dialog.find("input[name='page_ids[]']").remove();
  $dialog.find("input[name='part_ids[]']").remove();
  $dialog.find("input[name='layout_ids[]']").remove();
};


