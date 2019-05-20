this.Gws_Schedule_Todo_Index = (function () {
  function Gws_Schedule_Todo_Index(el) {
    this.$el = $(el);
    this.render();
  }

  var showEl = function($el) {
    $el.removeClass("hide");
  };

  var hideEl = function($el) {
    $el.addClass("hide");
  };

  var isExpanded = function($listItemHeader) {
    var status = $listItemHeader.find(".list-item-switch").html();
    return status === "expand_less";
  };

  Gws_Schedule_Todo_Index.prototype.render = function() {
    var self = this;

    this.$el.find(".gws-schedule-todo-list-item-header").on("click", function() {
      self.toggleListItems($(this));
    });
  };

  Gws_Schedule_Todo_Index.prototype.toggleListItems = function($listItemHeader) {
    if (isExpanded($listItemHeader)) {
      this.collapseListItems($listItemHeader);
    } else {
      this.expandListItems($listItemHeader);
    }
  };

  Gws_Schedule_Todo_Index.prototype.collapseListItems = function($listItemHeader) {
    $listItemHeader.find(".list-item-switch").html("expand_more");
    this.eachListItem($listItemHeader, function() {
      hideEl($(this));
    });
  };

  Gws_Schedule_Todo_Index.prototype.expandListItems = function($listItemHeader) {
    $listItemHeader.find(".list-item-switch").html("expand_less");

    this.eachListItem($listItemHeader, function() {
      var $this = $(this);
      if ($this.hasClass("gws-schedule-todo-list-item-header")) {
        showEl($(this));
      } else {
        if (isExpanded($this.prev(".gws-schedule-todo-list-item-header"))) {
          showEl($(this));
        }
      }
    });
  };

  Gws_Schedule_Todo_Index.prototype.eachListItem = function($listItemHeader, callback) {
    var targetGroup = $listItemHeader.data("group");
    var targetDepth = $listItemHeader.data("depth");

    $.each($listItemHeader.nextAll(".list-item"), function() {
      var $this = $(this);
      var group = $this.data("group");
      var depth = $this.data("depth");
      if (group !== targetGroup && depth <= targetDepth) {
        return false;
      }

      callback.apply(this);
    });
  };

  return Gws_Schedule_Todo_Index;

})();
