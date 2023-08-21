this.Openlayers_Dataset_Map = (function () {
  function Openlayers_Dataset_Map() {
  }

  Openlayers_Dataset_Map.map = null;
  Openlayers_Dataset_Map.map_points = null;

  Openlayers_Dataset_Map.render = function (selector, opts) {
    $(".dataset-search a#ajax-search").colorbox({
      fixed: true,
      width: "90%",
      height: "90%"
    });
    var canvas = $(selector)[0];
    Openlayers_Dataset_Map.map = new Openlayers_Map(canvas, opts);
  }

  Openlayers_Dataset_Map.selectItem = function (ele) {
    var dataset_id = $(ele).attr("data-id");
    var item = $(ele).find(".selected-item").clone(false);

    // remove renderInBox class
    $(item).find("a").removeClass("cboxElement");

    $(item).find('[name="resource_id"]').each(function (idx) {
      var resource_id = $(this).val();

      $(this).data("map_points", Openlayers_Dataset_Map.map_points[dataset_id][resource_id]);

      // checkbox
      $(this).on("click", function () {
        Openlayers_Dataset_Map.setMarkers();
        Openlayers_Dataset_Map.map.resize();
      });

      // select marker image
      $(this).closest("li").find(".marker-image-form .select-marker-image").on("click", function () {
        var form = $(this).closest(".marker-image-form");
        var images = $(form).find(".images");

        $(".marker-image-form .images").hide();

        images.show();
        $("body").not(this).one("click", function (e) {
          images.hide();
        });

        return false;
      });

      // marker images
      $(this).closest("li").find(".marker-image-form .images .image").on("click", function () {
        var form = $(this).closest(".marker-image-form");
        var images = $(form).find(".images");
        var thumb = $(form).find(".marker-thumb img");
        var src = $(this).find('img').andSelf("img").attr("src");

        form.data("src", src);
        thumb.attr("src", src);
        images.hide();

        Openlayers_Dataset_Map.setMarkers();
        return false;
      });
      $(this).closest("li").find(".marker-image-form .marker-thumb").html($('<img />', { src: Openlayers_Dataset_Map.map.markerIcon }));
    });

    // deselect button
    $(item).find(".deselect").on("click", function (e) {
      $(this).closest(".selected-item").remove();
      Openlayers_Dataset_Map.setMarkers();
      Openlayers_Dataset_Map.map.resize();
      return false;
    });

    // append and remove
    item.show();
    $(".dataset-search .selected-dataset").append(item);
      var length = $(".dataset-search .selected-dataset .selected-item").length - 10;
      for (var i = 0; i < length; i++) {
        $(".dataset-search .selected-dataset .selected-item:first").remove();
      }

    return item;
  }

  Openlayers_Dataset_Map.setMarkers = function () {
    Openlayers_Dataset_Map.map.removeMarkers();
    Openlayers_Dataset_Map.map.removeloadedLayers();
    $(".dataset-search .selected-item .set-markers:checked").each(function () {
      var map_points = $(this).data("map_points");
      var form = $(this).closest("li").find(".marker-image-form");

      if (form && form.data("src")) {
        $.each(map_points["points"], function(){
          this["image"] = form.data("src");
        });
      }

      if (map_points["points"]) {
        Openlayers_Dataset_Map.map.renderMarkers(map_points["points"]);
      } else if (map_points["format"] == "KML") {
        Openlayers_Dataset_Map.map.loadLayer(map_points["url"], ol.format.KML);
      } else if (map_points["format"] == "GEOJSON") {
        Openlayers_Dataset_Map.map.loadLayer(map_points["url"], ol.format.GeoJSON);
      }
    });
  };

  Openlayers_Dataset_Map.toggleSelectButton = function () {
    if ($(".search-ui .items input:checked").size() > 0) {
      $(".select-items").parent("div").show();
    } else {
      $(".select-items").parent("div").hide();
    }
  };

  Openlayers_Dataset_Map.modal = function (map_points) {
    Openlayers_Dataset_Map.map_points = map_points;

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
      var article = Openlayers_Dataset_Map.selectItem(tr);

      $.colorbox.close();
      $(article).find(".set-markers").trigger("click");

      return false;
    });

    // select items event
    $(".search-ui-select .select-items").on("click", function (e) {
      $(".search-ui .items .set-dataset:checked").each(function () {
        var tr = $(this).closest("tr");
        Openlayers_Dataset_Map.selectItem(tr);
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
        Openlayers_Dataset_Map.toggleSelectButton();
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

  return Openlayers_Dataset_Map;
})();
