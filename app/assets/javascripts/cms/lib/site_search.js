this.Cms_Site_Search = (function () {
  function Cms_Site_Search() {
  }

  Cms_Site_Search.render = function () {
    $(".ajax-box.article-nodes, .ajax-box.categories").colorbox({
      fixed: true,
      width: "90%",
      height: "90%"
    });
    $(".selected-article-nodes, .selected-categories").find(".deselect").on("click", function () {
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

    // append
    item.show();
    SS_SearchUI.anchorAjaxBox.closest("dl").find(".selected-article-nodes, .selected-categories").append(item);

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
    $(".search-ui-form form.search").on("submit", function (_e) {
      $(this).ajaxSubmit({
        url: $(this).attr("action"),
        success: function (data) {
          return $("#cboxLoadedContent").html(data);
        },
        error: function (_data, _status) {
          return alert("== Error(SiteSearch) ==");
        }
      });
      return false;
    });

    // select item event
    $(".search-ui a.select-item").on("click", function (_e) {
      SS_SearchUI.anchorAjaxBox.closest("dl").find(".selected-article-nodes, .selected-categories").html('');
      var tr = $(this).closest("tr");
      var article = Cms_Site_Search.selectItem(tr);

      $.colorbox.close();
      $(article).find(".set-graph:first").trigger("click");

      return false;
    });

    // select items event
    $(".search-ui-select .select-items").on("click", function (_e) {
      SS_SearchUI.anchorAjaxBox.closest("dl").find(".selected-article-nodes, .selected-categories").html('');
      $(".search-ui .items .set-article-node:checked, .search-ui .items .set-category:checked").each(function () {
        var tr = $(this).closest("tr");
        Cms_Site_Search.selectItem(tr);
      });
      $.colorbox.close();
      return false;
    });

    // list-head checkbox event
    $(".search-ui .list-head input:checkbox").on("change", function (_e) {
      var chk = $(this).prop('checked');
      $('.search-ui .list-item').each(function () {
        $(this).toggleClass('checked', chk);
        $(this).find('.set-article-node, .set-category').prop('checked', chk);
      });
    });

    // check selected items in modal
    $(".selected-categories .selected-item").each(function () {
      var name = $(this).attr("data-name");
      $(`#colorbox .items [data-name="${name}"] input[type=checkbox]`).prop('checked', true);
    });
    $(".selected-article-nodes .selected-item").each(function () {
      var id = $(this).attr("data-id");
      $(`#colorbox .items [data-id="${id}"] input[type=checkbox]`).prop('checked', true);
    });
  }

  return Cms_Site_Search;
})();
