this.Opendata_Dataset_Graph = (function () {
  function Opendata_Dataset_Graph() {
  }

  Opendata_Dataset_Graph.graph = null;
  Opendata_Dataset_Graph.$canvas = null;
  Opendata_Dataset_Graph.$controller = null;

  Opendata_Dataset_Graph.render = function (canvas, controller) {
    $(".dataset-search a#ajax-search").colorbox({
      fixed: true,
      width: "90%",
      height: "90%"
    });
    Opendata_Dataset_Graph.$canvas = $(canvas);
    Opendata_Dataset_Graph.$controller = $(controller);
    Opendata_Dataset_Graph.graph = new Opendata_Graph(
      Opendata_Dataset_Graph.$canvas,
      Opendata_Dataset_Graph.$controller
    );
  }

  Opendata_Dataset_Graph.renderGraph = function (type, header) {
    var ele = $('.selected-dataset [name="resource_id"]:checked:first');

    if (ele.length > 0) {
      var url = $(ele).data("url");
      var name = $(ele).closest("li").find(".resource-name").text();

      if (type) {
        url += "?type=" + type;
      }
      $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data) {
          var type = data["type"];
          var types = data["types"];
          var datasets = data["datasets"];
          var labels = data["labels"];
          var headers = data["headers"];

          if (type == "pie") {
            if (!header) {
              header = 0;
            }
            name += "（" + headers[header] + "）";
          }
          Opendata_Dataset_Graph.graph.render(type, name, labels, datasets, {headerIndex: header});
          Opendata_Dataset_Graph.graph.renderController(types, headers, function (type, header) {
            Opendata_Dataset_Graph.renderGraph(type, header);
          });
        }
      });
    } else {
      Opendata_Dataset_Graph.graph.destroy();
    }
  };

  Opendata_Dataset_Graph.selectItem = function (ele) {
    var dataset_id = $(ele).attr("data-id");
    var item = $(ele).find(".selected-item").clone(false);

    // remove renderInBox class
    $(item).find("a").removeClass("cboxElement");

    $(item).find('[name="resource_id"]').each(function (idx) {
      var resource_id = $(this).val();

      // checkbox
      $(this).on("click", function () {
        $(this).closest('.selected-dataset').find('[name="resource_id"]').not(this).prop("checked", false);
        Opendata_Dataset_Graph.renderGraph();
        Opendata_Dataset_Graph.toggleFirstNotice();
      });
    });

    // deselect button
    $(item).find(".deselect").on("click", function (e) {
      $(this).closest(".selected-item").remove();
      Opendata_Dataset_Graph.graph.destroy();
      Opendata_Dataset_Graph.toggleFirstNotice();
      return false;
    });

    // append and remove
    item.show();
    $(".dataset-search .selected-dataset").append(item);
    var length = $(".dataset-search .selected-dataset .selected-item").length - 10;
    for (var i = 0; i < length; i++) {
      $(".dataset-search .selected-dataset .selected-item:first").remove();
    }
    Opendata_Dataset_Graph.toggleFirstNotice();

    return item;
  }

  Opendata_Dataset_Graph.toggleSelectButton = function () {
    if ($(".search-ui .items input:checked").size() > 0) {
      $(".select-items").parent("div").show();
    } else {
      $(".select-items").parent("div").hide();
    }
  };

  Opendata_Dataset_Graph.toggleFirstNotice = function () {
    if ($('.selected-dataset [name="resource_id"]:checked').length > 0) {
      $(".resource-graph .first-notice").hide();
    } else {
      $(".resource-graph .first-notice").show();
    }
  };

  Opendata_Dataset_Graph.modal = function () {
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
      var article = Opendata_Dataset_Graph.selectItem(tr);

      $.colorbox.close();
      $(article).find(".set-graph:first").trigger("click");

      return false;
    });

    // select items event
    $(".search-ui-select .select-items").on("click", function (e) {
      $(".search-ui .items .set-dataset:checked").each(function () {
        var tr = $(this).closest("tr");
        Opendata_Dataset_Graph.selectItem(tr);
      });
      $.colorbox.close();
      return false;
    });

    // list-head checkbox event
    $(".search-ui .list-head input:checkbox").on("change", function (e) {
      var chk = $(this).prop('checked');
      $('.search-ui .list-item').each(function () {
        $(this).toggleClass('checked', chk);
        $(this).find('.set-dataset').prop('checked', chk);
      });
    });

    // toggle select items button event
    $(".search-ui").on("change", function (e) {
      Opendata_Dataset_Graph.toggleSelectButton();
    });

    // disable selected items in modal
    $(".dataset-search .selected-dataset .selected-item").each(function () {
      var id = $(this).attr("data-id");
      var tr = $(".items [data-id='" + id + "']");
      tr.find("input[type=checkbox]").remove();

      var item = tr.find(".select-item").html();
      tr.find(".select-item").replaceWith("<span class='select-item' style='color: #888'>" + item + "</span>");
    });
  }

  return Opendata_Dataset_Graph;
})();
