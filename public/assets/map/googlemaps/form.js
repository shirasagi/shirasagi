this.Map_Form = (function () {
  function Map_Form() {
  }

  Map_Form.maxPointForm = 10;

  Map_Form.deleteMessage = "マーカーを削除してよろしいですか？";

  Map_Form.dataID = 0;

  Map_Form.clickMarker = null;

  Map_Form.setMapLoc = function (ele, lat, lon) {
    lat = Math.ceil(lat * Math.pow(10, 6)) / Math.pow(10, 6);
    lon = Math.ceil(lon * Math.pow(10, 6)) / Math.pow(10, 6);
    ele.val(lat.toFixed(6) + "," + lon.toFixed(6));
  };

  Map_Form.getMapLoc = function (ele) {
    var latlon;
    latlon = ele.val().split(',');
    return new google.maps.LatLng(parseFloat(latlon[1]), parseFloat(latlon[0]));
  };

  Map_Form.validateLoc = function (loc) {
    var lat, latlon, lon;
    if (!loc) {
      return false;
    }
    latlon = loc.split(',');
    lat = parseFloat(latlon[1]);
    lon = parseFloat(latlon[0]);
    if (!(lat && !isNaN(lat))) {
      return false;
    }
    if (!(lon && !isNaN(lon))) {
      return false;
    }
    return Googlemaps_Map.validateLatLon(lat, lon);
  };

  Map_Form.attachMessage = function (id) {
    google.maps.event.addListener(Googlemaps_Map.markers[id], 'click', function (event) {
      if (Googlemaps_Map.openedInfo) {
        Googlemaps_Map.openedInfo.close();
      }
      $('dd[data-id = "' + id + '"]').each(function () {
        var markerHtml, name, text, loc;
        markerHtml = "";
        name = $(this).find(".marker-name").val();
        text = $(this).find(".marker-text").val();
        loc = $(this).find(".marker-loc-input").val();
        if (name !== "" || text !== "") {
          markerHtml = '<div class="marker-info">';
          if (name !== "") {
            markerHtml += '<p>' + name + '</p>';
          }
          if (text !== "") {
            $.each(text.split(/[\r\n]+/), function () {
              if (this.match(/^https?:\/\//)) {
                return markerHtml += '<p><a href="' + this + '">' + this + '</a></p>';
              } else {
                return markerHtml += '<p>' + this + '</p>';
              }
            });
          }
        }

        if (loc) {
          loc = loc.split(",");
          markerHtml += Googlemaps_Map.getMapsSearchHtml(loc[1], loc[0]);
        }
        if (markerHtml) {
          Googlemaps_Map.openedInfo = new google.maps.InfoWindow({
            content: markerHtml,
            maxWidth: 260
          });
          Googlemaps_Map.openedInfo.open(Googlemaps_Map.markers[id].getMap(), Googlemaps_Map.markers[id]);
        }

        return false;
      });
    });
  };

  Map_Form.geocoderSearch = function (address) {
    var geocoder;
    geocoder = new google.maps.Geocoder();
    geocoder.geocode({
      "address": address,
      "region": "jp"
    }, function (results, status) {
      var result;
      if (status === google.maps.GeocoderStatus.OK) {
        result = results[0];
        Googlemaps_Map.map.setCenter(result.geometry.location);
        if (result.geometry.viewport) {
          Googlemaps_Map.map.fitBounds(result.geometry.viewport);
        }
      } else {
        alert("座標を取得できませんでした。");
      }
    });
    return false;
  };

  Map_Form.clonePointForm = function () {
    var cln;
    if ($(".mod-map dd.marker").length < Map_Form.maxPointForm) {
      cln = $(".mod-map dd.marker:last").clone(false).insertAfter($(".mod-map dd.marker:last"));
      cln.attr("data-id", Map_Form.dataID);
      Map_Form.dataID += 1;
      cln.removeClass("active");
      cln.find("input,textarea").val("");
      cln.find(".marker-name").val("");
      cln.find(".clear-marker").on('click', function () {
        return Map_Form.clearPointForm(cln);
      });
      cln.find(".set-marker").on('click', function () {
        return Map_Form.clickSetMarker(cln);
      });
      cln.find(".marker-name").on('keypress', function (e) {
        if (e.which === SS.KEY_ENTER) {
          return false;
        }
      });
      cln.find(".marker-loc-input").on('keypress', function (e) {
        if (e.which === SS.KEY_ENTER) {
          $(this).closest("dd.marker").find(".set-marker").trigger("click");
          return false;
        }
      });
      cln.find(".marker-loc-input").on('focus', function (e) {
        if (Map_Form.clickMarker !== null) {
          Map_Form.clickMarker.setMap(null);
          return $(".mod-map .clicked").val("");
        }
      });

      cln.find(".images").hide();
      cln.find(".select-marker-image").on("click", function (e) {
        var marker = $(e.target).closest(".marker");
        Map_Form.openMarkerImages(marker);
        return false;
      });
      cln.find(".marker-thumb").html($('<img src="' + Googlemaps_Map.markerIcon + '">'));
      cln.find(".images .image").on("click", function (e) {
        Map_Form.selectMarkerImage(e.target);
        Map_Form.setMarkerThumb($(e.target).closest(".marker"));
        return false;
      });
      //cln.find(".marker-setting .marker").each(function () {
      //  Map_Form.setMarkerThumb(this);
      //});
    }
    Map_Form.toggleAddMarker();
  };

  Map_Form.clearPointForm = function (ele) {
    if (ele.find(".marker-loc").val() !== "") {
      if (confirm(Map_Form.deleteMessage)) {
        ele.removeClass("active");
        if (Googlemaps_Map.markers[parseInt(ele.attr("data-id"))]) {
          Googlemaps_Map.markers[parseInt(ele.attr("data-id"))].setMap(null);
        }
        ele.find("input,textarea").val("");
        if ($(".mod-map dd.marker").length > 1) {
          ele.remove();
        }
      }
    } else {
      ele.removeClass("active");
      if (Googlemaps_Map.markers[parseInt(ele.attr("data-id"))]) {
        Googlemaps_Map.markers[parseInt(ele.attr("data-id"))].setMap(null);
      }
      ele.find("input,textarea").val("");
      if ($(".mod-map dd.marker").length > 1) {
        ele.remove();
      }
    }
    Map_Form.toggleAddMarker();
  };

  Map_Form.toggleAddMarker = function () {
    if ($(".mod-map dd.marker").length < Map_Form.maxPointForm) {
      $(".mod-map dd .add-marker").parent().show();
    } else {
      $(".mod-map dd .add-marker").parent().hide();
    }
  };

  Map_Form.openMarkerImages = function (marker) {
    var markers = $(marker).closest(".marker-setting")
    var images = $(marker).find(".images");

    markers.find(".marker .images").hide();
    images.show();
    $("body").not(this).one("click", function (e) {
      images.hide();
    });
  };

  Map_Form.selectMarkerImage = function (image) {
    var marker = $(image).closest(".marker");
    var images = $(image).closest(".images");
    var url = $(image).find('img').andSelf("img").attr("src");
    var loc;

    images.hide();
    marker.find('[name="item[map_points][][image]"]').val(url);

    loc = marker.find(".marker-loc-input").val();
    if (loc) {
      Map_Form.createMarker(marker, loc);
      return false;
    }

    loc = $(".mod-map .clicked").val();
    if (loc) {
      Map_Form.removeClickMarker();
      Map_Form.createMarker(marker, loc);
      return false;
    }

    return false;
  };

  Map_Form.setMarkerThumb = function (marker) {
    var thumb = $(marker).find(".marker-thumb");
    var url = $(marker).find('[name="item[map_points][][image]"]').val();

    if (url) {
      $(thumb).html($('<img src="' + url + '">'));
    } else {
      $(thumb).html($('<img src="' + Googlemaps_Map.markerIcon + '">'));
    }
  };

  Map_Form.clickSetMarker = function (ele) {
    var loc;
    if ($(".mod-map .clicked").val() !== "") {
      loc = $(".mod-map .clicked").val();
      Map_Form.removeClickMarker();
    } else if (ele.find(".marker-loc-input").val() !== "") {
      loc = ele.find(".marker-loc-input").val();
    } else {
      return;
    }
    Map_Form.createMarker(ele, loc);
  };

  Map_Form.removeClickMarker = function () {
    if (Map_Form.clickMarker) {
      $(".mod-map .clicked").val("");
      Map_Form.clickMarker.setMap(null);
    }
  };

  Map_Form.createMarker = function (ele, loc) {
    var dataId, opts, image;

    if (!Map_Form.validateLoc(loc)) {
      alert("正しい座標をカンマ(,)区切りで入力してください。\\n例）133.6806607,33.8957612");
      return;
    }

    ele.find(".marker-loc").val(loc);
    ele.find(".marker-loc-input").val(loc);
    ele.addClass("active");
    dataId = parseInt(ele.attr("data-id"));
    if (Googlemaps_Map.markers[dataId]) {
      Googlemaps_Map.markers[dataId].setMap(null);
    }

    image = ele.find('[name="item[map_points][][image]"]').val();
    opts = {
      position: Map_Form.getMapLoc(ele.find(".marker-loc")),
      map: Googlemaps_Map.map
    };
    if (image) {
      opts["icon"] = image;
    } else {
      opts["icon"] = Googlemaps_Map.markerIcon;
    }

    Googlemaps_Map.markers[dataId] = new google.maps.Marker(opts);
    Map_Form.attachMessage(dataId);
    Map_Form.removeClickMarker();
  };

  Map_Form.renderMarkers = function () {
    var i, len, markerBounds;
    markerBounds = new google.maps.LatLngBounds();
    if (Googlemaps_Map.markers) {
      var ref = Googlemaps_Map.markers;
      for (i = 0, len = ref.length; i < len; i++) {
        var m = ref[i];
        m.setMap(null);
      }
    }
    Googlemaps_Map.markers = [];
    Map_Form.dataID = 0;
    $(".mod-map dd.marker").each(function () {
      $(this).attr("data-id", Map_Form.dataID);
      if ($(this).find(".marker-loc").val() !== "") {
        var loc = Map_Form.getMapLoc($(this).find(".marker-loc"));
        var image = $(this).find('[name="item[map_points][][image]"]').val();
        var opts = {};

        opts = {
          position: loc,
          map: Googlemaps_Map.map
        };
        if (image) {
          opts["icon"] = image;
        } else {
          opts["icon"] = Googlemaps_Map.markerIcon;
        }
        Googlemaps_Map.markers[Map_Form.dataID] = new google.maps.Marker(opts);
        Map_Form.attachMessage(Map_Form.dataID);
        markerBounds.extend(loc);
      }
      Map_Form.dataID += 1;
    });

    Map_Form.toggleAddMarker();
    Googlemaps_Map.adjustMarkerBounds(Googlemaps_Map.markers.length, markerBounds);
  };

  Map_Form.renderEvents = function () {
    google.maps.event.addListener(Googlemaps_Map.map, 'click', function (event) {
      Map_Form.setMapLoc($(".mod-map .clicked"), event.latLng.lng(), event.latLng.lat());
      if (Map_Form.clickMarker !== null) {
        Map_Form.clickMarker.setMap(null);
      }
      return Map_Form.clickMarker = new google.maps.Marker({
        position: new google.maps.LatLng(event.latLng.lat(), event.latLng.lng()),
        icon: Googlemaps_Map.clickIcon,
        map: Googlemaps_Map.map
      });
    });
    google.maps.event.addListener(Googlemaps_Map.map, 'bounds_changed', function (event) {
      var zoom = Googlemaps_Map.map.getZoom();
      $('input[name="item[map_zoom_level]"]').val(zoom);
    });
    $(".mod-map .add-marker").on('click', function (e) {
      Map_Form.clonePointForm();
      return false;
    });
    $(".mod-map .clear-marker").on('click', function (e) {
      Map_Form.clearPointForm($(this).closest("dd.marker"));
      return false;
    });
    $(".mod-map .set-center-position").on('click', function () {
      var latlng = Googlemaps_Map.map.getCenter();
      var lat = Math.floor((latlng.lat() * 1000000)) / 1000000;
      var lng = Math.floor((latlng.lng() * 1000000)) / 1000000;
      $(".center-input").val(lng + "," + lat);
      return false;
    });
    $(".mod-map .set-zoom-level").on('click', function () {
      $(".zoom-input").val(Googlemaps_Map.map.getZoom());
      return false;
    });
    $(".mod-map .set-marker").on('click', function (e) {
      Map_Form.clickSetMarker($(this).closest("dd.marker"));
      return false;
    });
    $(".mod-map .location-search button").on('click', function (e) {
      Map_Form.geocoderSearch($(".mod-map .keyword").val());
      return false;
    });
    $(".mod-map .keyword").on('keypress', function (e) {
      if (e.which === SS.KEY_ENTER) {
        Map_Form.geocoderSearch($(this).val());
        return false;
      }
    });
    $(".mod-map .marker-name").on('keypress', function (e) {
      if (e.which === SS.KEY_ENTER) {
        return false;
      }
    });
    $(".mod-map .marker-loc-input").on('keypress', function (e) {
      if (e.which === SS.KEY_ENTER) {
        $(this).closest("dd.marker").find(".set-marker").trigger("click");
        return false;
      }
    });
    $(".mod-map .marker-loc-input").on('focus', function (e) {
      if (Map_Form.clickMarker !== null) {
        Map_Form.clickMarker.setMap(null);
        return $(".mod-map .clicked").val("");
      }
    });
    $(".mod-map .select-marker-image").on("click", function (e) {
      var marker = $(e.target).closest(".marker");
      Map_Form.openMarkerImages(marker);
      return false;
    });
    $(".mod-map .images .image").on("click", function (e) {
      Map_Form.selectMarkerImage(e.target);
      Map_Form.setMarkerThumb($(e.target).closest(".marker"));
      return false;
    });
    $(".mod-map .marker-setting .marker").each(function () {
      Map_Form.setMarkerThumb(this);
    });
  };

  return Map_Form;
})();
