this.Openlayers_Facility_Search = (function () {
  function Openlayers_Facility_Search() {
  }

  Openlayers_Facility_Search.render = function (selector, opts) {
    var canvas, map, overrided, slideSidebar;
    //define function
    if (opts == null) {
      opts = {};
    }
    slideSidebar = function (column) {
      var columnTop, indexTop, scrolled;
      columnTop = column.offset().top;
      indexTop = column.closest("#map-sidebar").offset().top;
      scrolled = column.closest("#map-sidebar").scrollTop();
      return column.closest("#map-sidebar").animate({
        scrollTop: columnTop - indexTop + scrolled
      }, 'fast');
    };
    //setup map
    canvas = $(selector)[0];
    map = new Openlayers_Map(canvas, opts);
    //setup markers
    overrided = map.showPopup;
    map.showPopup = function (feature, coordinate) {
      var column, dataId;
      overrided.call(map, feature, coordinate);
      $("#map-sidebar .column").removeClass("current");
      dataId = feature.get("markerId");
      column = $('#map-sidebar .column[data-id="' + dataId + '"]');
      column.addClass("current");
      return slideSidebar(column);
      //setup sidebar
    };
    $("#map-sidebar .column .click-marker").on("click", function () {
      var coordinate, dataId, marker;
      dataId = parseInt($(this).closest(".column").attr("data-id"));
      $("#map-sidebar .column").removeClass("current");
      marker = map.getMarker(dataId);
      if (!marker) {
        return false;
      }
      coordinate = marker.getGeometry().getCoordinates();
      map.showPopup(marker, coordinate);
      return false;
    });
    $(".filters a").on("click", function () {
      var dataIds, markers;
      if ($(this).hasClass("clicked")) {
        $(this).removeClass("clicked");
      } else {
        $(this).addClass("clicked");
      }
      dataIds = [];
      $(".filters a.clicked").each(function () {
        return dataIds.push(parseInt($(this).attr("data-id")));
      });
      markers = map.getMarkers();
      $.each(markers, function () {
        var category, column, dataId, iconSrc, style, visible;
        visible = false;
        category = this.get("category");
        $.each(dataIds, function () {
          if ($.inArray(parseInt(this), category) >= 0) {
            visible = true;
            return false;
          }
        });
        dataId = this.get("markerId");
        column = $('#map-sidebar .column[data-id="' + dataId + '"]');
        map.popup.hide();
        if (visible) {
          iconSrc = this.get("iconSrc");
          style = map.createMarkerStyle(iconSrc);
          this.setStyle(style);
          column.show();
          return
        } else {
          style = new ol.style.Style({});
          this.setStyle(style);
          column.hide();
          return
        }
      });
      return false;
    });
    //setup location filter
    return $(".filters .focus").on("change", function () {
      var select;
      select = $(this);
      return select.find("option:selected").each(function () {
        var loc, pos, zoomLevel;
        if ($(this).val() === "") {
          return false;
        }
        loc = $(this).val().split(",");
        zoomLevel = $(this).attr("data-zoom-level");
        pos = [parseFloat(loc[1]), parseFloat(loc[0])];
        map.setCenter(pos);
        if (zoomLevel) {
          map.setZoom(parseInt(zoomLevel));
        }
        return select.val("");
      });
    });
  };

  return Openlayers_Facility_Search;
})();
