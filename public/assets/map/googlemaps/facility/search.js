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
      column.closest("#map-sidebar").animate({
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
        if (column.length) {
          column.addClass("current");
          slideSidebar(column);
        }
      });
      google.maps.event.addListener(Googlemaps_Map.markers[id]["window"], 'closeclick', function (event) {
        $("#map-sidebar .column").removeClass("current");
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
          if (Googlemaps_Map.markerClusterer) {
            var cluster = Googlemaps_Map.markerClusterer.clusters_.find(function(cluster) {
              if (cluster.getMarkers().length === 1) return false;
              return cluster.getMarkers().find(function(marker) {
                return marker.position === m.marker.position;
              });
            });
            if (cluster) {
              m["window"].setPosition(cluster.getMarkers()[0].position);
              m["window"].pixelOffset = new google.maps.Size(0, -15);
            }
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
      $(this).toggleClass("clicked").blur();
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
          column.show();
        } else {
          Googlemaps_Map.markers[id]["marker"].setVisible(false);
          if (Googlemaps_Map.markers[id]["window"]) {
            Googlemaps_Map.markers[id]["window"].close();
          }
          column.hide();
        }
      });

      $('#map-sidebar .column[data-cate-id]').each(function() {
        var column = $(this);
        var cateID = parseInt(column.attr('data-cate-id'));
        var exists = $.inArray(cateID, dataIDs) >= 0;
        column.toggle(exists);
      });

      var resultSize = $('#map-sidebar .column:visible').length;
      $('.map-search-result .number').text(resultSize);

      if (Googlemaps_Map.openedInfo) {
        Googlemaps_Map.openedInfo.close();
        Googlemaps_Map.openedInfo = null;
      }
      if (Googlemaps_Map.markerClusterer) {
        Googlemaps_Map.markerClusterer.repaint();
        Googlemaps_Map.closeMarkerClusterInfo();
      }
      return false;
    });

    //setup location filter
    $(".filters .focus").on("change", function () {
      var select;
      select = $(this);
      select.find("option:selected").each(function () {
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
        select.val("");
      });
    });

    //click selected category
    $('.map-search-condition .category-settings').each(function() {
      var settings = $(this).attr('data-category-settings');
      if (!settings) return false;
      $('.map-search-index .filters a').each(function() {
        var $btn = $(this);
        if (!settings.includes($btn.text())) {
          $btn.click();
        }
      });
    });
  };

  return Facility_Search;
})();
