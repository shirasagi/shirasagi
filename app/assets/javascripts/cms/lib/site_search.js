this.Cms_Site_Search = (function () {
  function Cms_Site_Search() {
  }

  Cms_Site_Search.render = function () {
    $(".ajax-box.categories").colorbox({
      fixed: true,
      width: "90%",
      height: "90%"
    });
    $(".selected-categories").find(".deselect").on("click", function () {
      $(this).closest(".selected-item").remove();
      return false;
    });
  }

  Cms_Site_Search.selectItem = function (ele) {
    var item = $(ele).find(".selected-item").clone(false);

    // remove renderInBox class
    $(item).find("a").removeClass("cboxElement");

    // deselect button
    $(item).find(".deselect").on("click", function () {
      $(this).closest(".selected-item").remove();
      return false;
    });

    // append and remove
    item.show();
    $(".selected-categories").append(item);
    // var length = $(".selected-categories .selected-item").length - 10;
    // for (var i = 0; i < length; i++) {
    //   $(".selected-categories .selected-item:first").remove();
    // }

    return item;
  }

  Cms_Site_Search.toggleSelectButton = function () {
    if ($(".search-ui .items input:checked").size() > 0) {
      $(".select-items").parent("div").show();
    } else {
      $(".select-items").parent("div").hide();
    }
  };

  Cms_Site_Search.modal = function () {
    // form search event
    $(".search-ui-form form.search").on("submit", function (e) {
      $(this).ajaxSubmit({
        url: $(this).attr("action"),
        success: function (data) {
          return $("#cboxLoadedContent").html(data);
        },
        error: function (data, status) {
          return alert("== Error ==");
        }
      });
      return false;
    });

    // select item event
    $(".search-ui a.select-item").on("click", function (e) {
      var tr = $(this).closest("tr");
      var article = Cms_Site_Search.selectItem(tr);

      $.colorbox.close();
      $(article).find(".set-graph:first").trigger("click");

      return false;
    });

    // select items event
    $(".search-ui-select .select-items").on("click", function (e) {
      $(".search-ui .items .set-category:checked").each(function () {
        var tr = $(this).closest("tr");
        Cms_Site_Search.selectItem(tr);
      });
      $.colorbox.close();
      return false;
    });

    // list-head checkbox event
    $(".search-ui .list-head input:checkbox").on("change", function (e) {
      var chk = $(this).prop('checked');
      $('.search-ui .list-item').each(function () {
        $(this).toggleClass('checked', chk);
        $(this).find('.set-category').prop('checked', chk);
      });
    });

    // toggle select items button event
    $(".search-ui").on("change", function (e) {
      Cms_Site_Search.toggleSelectButton();
    });

    // disable selected items in modal
    $(".selected-categories .selected-item").each(function () {
      var name = $(this).attr("data-name");
      var tr = $(".items [data-name='" + name + "']");
      tr.find("input[type=checkbox]").remove();

      var item = tr.find(".select-item").html();
      tr.find(".select-item").replaceWith("<span class='select-item' style='color: #888'>" + item + "</span>");
    });
  }

  return Cms_Site_Search;
})();
