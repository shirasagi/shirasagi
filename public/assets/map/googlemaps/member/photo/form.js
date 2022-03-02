this.Member_Photo_Form = (function () {
  function Member_Photo_Form() {
  }

  Member_Photo_Form.maxPointForm = 10;

  Member_Photo_Form.deleteMessage = "マーカーを削除してよろしいですか？";

  Member_Photo_Form.setExifMessage = "画像に位置情報が含まれています。位置情報を地図に設定しますか？";

  Member_Photo_Form.dataID = 0;

  Member_Photo_Form.clickMarker = null;

  Member_Photo_Form.setMapLoc = function (ele, lat, lon) {
    lat = Math.ceil(lat * Math.pow(10, 6)) / Math.pow(10, 6);
    lon = Math.ceil(lon * Math.pow(10, 6)) / Math.pow(10, 6);
    ele.val(lat.toFixed(6) + "," + lon.toFixed(6));
  };

  Member_Photo_Form.getMapLoc = function (ele) {
    var latlon;
    latlon = ele.val().split(',');
    return new google.maps.LatLng(parseFloat(latlon[1]), parseFloat(latlon[0]));
  };

  Member_Photo_Form.attachMessage = function (id) {
    google.maps.event.addListener(Googlemaps_Map.markers[id], 'click', function (event) {
      if (Googlemaps_Map.openedInfo) {
        Googlemaps_Map.openedInfo.close();
      }
      $('dd[data-id = "' + id + '"]').each(function () {
        var markerHtml, name, text;
        name = $(this).find(".marker-name").val();
        text = $(this).find(".marker-text").val();
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

  Member_Photo_Form.clearMarker = function (ele) {
    var dataId;
    dataId = 0;
    if (ele.val() !== "") {
      if (confirm(Member_Photo_Form.deleteMessage)) {
        if (Googlemaps_Map.markers[dataId]) {
          Googlemaps_Map.markers[dataId].setMap(null);
          ele.val("");
        }
      }
    } else {
      if (Googlemaps_Map.markers[dataId]) {
        Googlemaps_Map.markers[dataId].setMap(null);
      }
    }
  };

  Member_Photo_Form.createMarker = function (ele) {
    var dataId;
    if ($(".mod-map .clicked").val() !== "") {
      ele.val($(".mod-map .clicked").val());
      dataId = 0;
      if (Googlemaps_Map.markers[dataId]) {
        Googlemaps_Map.markers[dataId].setMap(null);
      }
      Googlemaps_Map.markers[dataId] = new google.maps.Marker({
        position: Member_Photo_Form.getMapLoc($(".mod-map .marker-loc")),
        map: Googlemaps_Map.map,
        icon: Googlemaps_Map.markerIcon
      });
      Member_Photo_Form.attachMessage(dataId);
    }
  };

  Member_Photo_Form.renderMarkers = function () {
    var i, len, m, markerBounds, ref, zoomChangeBoundsListener;
    markerBounds = new google.maps.LatLngBounds();
    if (Googlemaps_Map.markers) {
      ref = Googlemaps_Map.markers;
      for (i = 0, len = ref.length; i < len; i++) {
        m = ref[i];
        m.setMap(null);
      }
    }

    Googlemaps_Map.markers = [];
    Member_Photo_Form.dataID = 0;
    $(".mod-map .marker").each(function () {
      var loc;
      $(this).attr("data-id", Member_Photo_Form.dataID);
      if ($(this).find(".marker-loc").val() !== "") {
        loc = Member_Photo_Form.getMapLoc($(this).find(".marker-loc"));
        Googlemaps_Map.markers[Member_Photo_Form.dataID] = new google.maps.Marker({
          position: loc,
          map: Googlemaps_Map.map,
          icon: Googlemaps_Map.markerIcon
        });
        Member_Photo_Form.attachMessage(Member_Photo_Form.dataID);
        markerBounds.extend(loc);
      }
      return Member_Photo_Form.dataID += 1;
    });
    Googlemaps_Map.adjustMarkerBounds(Googlemaps_Map.markers.length, markerBounds);
  };

  Member_Photo_Form.setExifLatLng = function (selector) {
    return $(selector).on("change", function (e) {
      if (!e.target.files[0]) {
        return;
      }
      return EXIF.getData(e.target.files[0], function () {
        var lat, latRef, lon, lonRef;
        lat = EXIF.getTag(this, 'GPSLatitude');
        lon = EXIF.getTag(this, 'GPSLongitude');
        latRef = EXIF.getTag(this, 'GPSLatitudeRef') || "N";
        lonRef = EXIF.getTag(this, 'GPSLongitudeRef') || "W";
        if (!(lat && lon)) {
          return false;
        }
        if (!confirm(Member_Photo_Form.setExifMessage)) {
          return false;
        }
        latRef = latRef === "N" ? 1 : -1;
        lonRef = lonRef === "W" ? -1 : 1;
        lat = (lat[0] + (lat[1] / 60) + (lat[2] / 3600)) * latRef;
        lon = (lon[0] + (lon[1] / 60) + (lon[2] / 3600)) * lonRef;
        $(".mod-map .clicked").val([lat, lon].join());
        Member_Photo_Form.createMarker($(".mod-map .marker-loc"));
        return Googlemaps_Map.map.setCenter(new google.maps.LatLng(lon, lat));
      });
    });
  };

  Member_Photo_Form.renderEvents = function () {
    google.maps.event.addListener(Googlemaps_Map.map, 'click', function (event) {
      Member_Photo_Form.setMapLoc($(".mod-map .clicked"), event.latLng.lng(), event.latLng.lat());
      return Member_Photo_Form.createMarker($(".mod-map .marker-loc"));
    });
    $(".mod-map .clear-marker").on('click', function (e) {
      Member_Photo_Form.clearMarker($(".mod-map .marker-loc"));
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
    google.maps.event.addListener(Googlemaps_Map.map, 'bounds_changed', function (event) {
      var zoom = Googlemaps_Map.map.getZoom();
      $('input[name="item[map_zoom_level]"]').val(zoom);
    });
  };

  return Member_Photo_Form;
})();
