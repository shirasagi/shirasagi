this.Event_Monthly = (function () {
  function Event_Monthly() {
  }

  Event_Monthly.render = function () {
    $(".event-pages-filter a[data-id!=all]").on('click', function () {
      $(".event-pages-filter a[data-id=all]").removeClass("clicked");

      if ($(this).hasClass("clicked")) {
        $(this).removeClass("clicked");
      } else {
        $(this).addClass("clicked");
      }

      var dataIds = [];
      $(".event-pages-filter a.clicked").each(function () {
        var dataId = parseInt($(this).attr("data-id"));
        if (!isNaN(dataId)) {
          return dataIds.push(dataId);
        }
      });

      $("#event-list .page").each(function () {
        var pageDataIds = [];
        $.each($(this).attr("data-id").split(" "), function () {
          return pageDataIds.push(parseInt(this));
        });

        var visible = false;
        $.each(dataIds, function () {
          if ($.inArray(parseInt(this), pageDataIds) >= 0) {
            visible = true;
            return false;
          }
        });

        if (visible) {
          return $(this).show();
        } else {
          return $(this).hide();
        }
      });
      return false;
    });

    $(".event-pages-filter a[data-id=all]").on('click', function () {
      if (!$(this).hasClass("clicked")) {
        $(this).addClass("clicked");
        $(".event-pages-filter a[data-id!=all]").removeClass("clicked");
        $("#event-list .page").show();
      }
      return false;
    });
  };

  return Event_Monthly;

})();
