this.Gws_Schedule_Todo_Search = (function () {
  function Gws_Schedule_Todo_Search(el) {
    this.$el = $(el);
    this.templateHtml = this.$el.find("#schedule-todo-selected-member-template").html();

    this.render();
  }

  Gws_Schedule_Todo_Search.prototype.render = function() {
    var self = this;

    this.$el.find("select.schedule-todo-auto-submit").on("change", function() {
      self.scheduleToSubmit();
    });

    var $btn = this.$el.find(".schedule-todo-member-select-btn");
    if ($btn[0]) {
      var href = $btn.data("href");
      $btn.colorbox({ href: href, width: "90%", height: "90%" });

      $btn.data("on-select", function ($item) {
        var $x = $item.closest("[data-id]");
        if ($x.length === 0) {
          return;
        }

        self.selectUser($x.data());
      });

      this.$el.on("click", ".schedule-todo-selected-member .dismiss", function () {
        $(this).closest(".schedule-todo-selected-member").remove();
        self.scheduleToSubmit();
      });
    }
  };

  Gws_Schedule_Todo_Search.prototype.selectUser = function(userData) {
    var id = userData.id;
    var name = userData.longName;

    if (this.$el.find(".schedule-todo-selected-member[data-id=" + id + "]").length > 0) {
      return;
    }

    var html = this.templateHtml.replace(/#id/g, id).replace(/#name/g, name);
    this.$el.find(".schedule-todo-selected-members").append(html).removeClass("hide");
    this.scheduleToSubmit();
  };

  Gws_Schedule_Todo_Search.prototype.scheduleToSubmit = function() {
    if (this.timerId) {
      return;
    }

    var self = this;
    this.timerId = setTimeout(function() { self.$el[0].requestSubmit(); }, 0);
  };

  return Gws_Schedule_Todo_Search;

})();
