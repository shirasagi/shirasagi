this.Facility_Search = (function () {
  function Facility_Search() {
  }

  Facility_Search.render = function (selector, opts) {
    var markers, overrided, slideSidebar;
    if (opts == null) {
      //define functions
      opts = {};
    }
    markers = opts["markers"];
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
    Googlemaps_Map.load(selector, opts);
    //setup markers
    overrided = Googlemaps_Map.attachMessage;
    Googlemaps_Map.attachMessage = function (id) {
      overrided(id);
      google.maps.event.addListener(Googlemaps_Map.markers[id]["marker"], 'click', function (event) {
        var column, dataID;
        $("#map-sidebar .column").removeClass("current");
        dataID = Googlemaps_Map.markers[id]["id"];
        column = $('#map-sidebar .column[data-id="' + dataID + '"]');
        column.addClass("current");
        return slideSidebar(column);
      });
      return google.maps.event.addListener(Googlemaps_Map.markers[id]["window"], 'closeclick', function (event) {
        return $("#map-sidebar .column").removeClass("current");
      });
    };
    Googlemaps_Map.setMarkers(markers, { markerCluster: opts['markerCluster'] });
    //setup sidebar
    $("#map-sidebar .column .click-marker").on("click", function () {
      var dataID;
      dataID = parseInt($(this).closest(".column").attr("data-id"));
      $("#map-sidebar .column").removeClass("current");
      $.each(Googlemaps_Map.markers, function (i, m) {
        var column;
        if (dataID === m["id"]) {
          var cluster = Googlemaps_Map.markerClusterer.clusters_.find(function(cluster) {
            if (cluster.getMarkers().length === 1) return false;
            return cluster.getMarkers().find(function(marker) {
              return marker.position === m.marker.position;
            });
          });
          if (cluster) {
            m["window"].setPosition(cluster.getMarkers()[0].position);
            m["window"].pixelOffset = new google.maps.Size(0, -15);
            console.log(cluster)
          }

          if (Googlemaps_Map.openedInfo) {
            Googlemaps_Map.openedInfo.close();
          }
          m["window"].open(m["marker"].getMap() || Googlemaps_Map.map, m["marker"]);
          Googlemaps_Map.openedInfo = m["window"];
          column = $('#map-sidebar .column[data-id="' + dataID + '"]');
          column.addClass("current");
          slideSidebar(column);
          return false;
        }
      });

      return false;
    });
    //setup category filter
    $(".filters a").on("click", function () {
      var dataIDs;
      if ($(this).hasClass("clicked")) {
        $(this).removeClass("clicked");
      } else {
        $(this).addClass("clicked");
      }
      dataIDs = [];
      $(".filters a.clicked").each(function () {
        return dataIDs.push(parseInt($(this).attr("data-id")));
      });
      $.each(Googlemaps_Map.markers, function (id, value) {
        var column, dataID, visible;
        visible = false;
        $.each(dataIDs, function () {
          if ($.inArray(parseInt(this), Googlemaps_Map.markers[id]["category"]) >= 0) {
            visible = true;
            return false;
          }
        });
        dataID = Googlemaps_Map.markers[id]["id"];
        column = $('#map-sidebar .column[data-id="' + dataID + '"]');
        if (visible) {
          Googlemaps_Map.markers[id]["marker"].setVisible(true);
          return column.show();
        } else {
          Googlemaps_Map.markers[id]["marker"].setVisible(false);
          Googlemaps_Map.markers[id]["window"].close();
          return column.hide();
        }
      });
      return false;
    });
    //setup location filter
    return $(".filters .focus").on("change", function () {
      var select;
      select = $(this);
      return select.find("option:selected").each(function () {
        var latlng, loc, zoomLevel;
        if ($(this).val() === "") {
          return false;
        }
        loc = $(this).val().split(",");
        zoomLevel = $(this).attr("data-zoom-level");
        latlng = new google.maps.LatLng(loc[0], loc[1]);
        Googlemaps_Map.map.setCenter(latlng);
        if (zoomLevel) {
          Googlemaps_Map.map.setZoom(parseInt(zoomLevel));
        }
        return select.val("");
      });
    });
  };

  return Facility_Search;
})();
