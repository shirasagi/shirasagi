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

    var self = this;
    this.eachListItem($listItemHeader, function() {
      var $this = $(this);
      if (self.examineToShow($this)) {
        showEl($(this));
      }
    });
  };

  Gws_Schedule_Todo_Index.prototype.examineToShow = function($listItem) {
    if ($listItem.hasClass("gws-schedule-todo-list-item-header")) {
      var parentGroup = $listItem.data("parent");
      if (parentGroup) {
        return this.examineToShow(this.$el.find("#" + parentGroup));
      }

      return true;
    }

    var listItemGroup = $listItem.data("group");
    var $listItemHeader = this.$el.find("#" + listItemGroup);
    if (!isExpanded($listItemHeader)) {
      return false;
    }

    var parentGroup = $listItemHeader.data("parent");
    if (parentGroup) {
      return this.examineToShow(this.$el.find("#" + parentGroup));
    }

    return true;
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
