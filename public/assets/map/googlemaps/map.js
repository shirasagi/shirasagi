this.Googlemaps_Map = (function () {
  function Googlemaps_Map() {
  }

  Googlemaps_Map.map = null;

  Googlemaps_Map.form = null;

  Googlemaps_Map.center = null; // null means auto

  Googlemaps_Map.zoom = null; // null means auto

  Googlemaps_Map.defaultCenter = [36.204824, 138.252924];

  Googlemaps_Map.defaultZoom = 13;

  Googlemaps_Map.markers = null;

  Googlemaps_Map.markerClusterer = null;

  Googlemaps_Map.markerIcon = "/assets/img/googlemaps/marker1.png";

  Googlemaps_Map.clickIcon = "/assets/img/googlemaps/marker17.png";

  Googlemaps_Map.openedInfo = null;

  Googlemaps_Map.resized = null;

  Googlemaps_Map.kmlLayer = null;

  Googlemaps_Map.showGoogleMapsSearch = false;

  Googlemaps_Map.mapsSearchUrl = "https://www.google.co.jp/maps/search/";

  Googlemaps_Map.attachMessage = function (id) {
    google.maps.event.addListener(Googlemaps_Map.markers[id]["marker"], 'click', function (_event) {
      if (Googlemaps_Map.openedInfo) {
        Googlemaps_Map.openedInfo.close();
      }
      if (Googlemaps_Map.markers[id]["window"]) {
        Googlemaps_Map.markers[id]["window"].open(Googlemaps_Map.markers[id]["marker"].getMap(), Googlemaps_Map.markers[id]["marker"]);
      }
      Googlemaps_Map.openedInfo = Googlemaps_Map.markers[id]["window"];
    });
    return google.maps.event.addListener(Googlemaps_Map.markers[id]["window"], 'closeclick', function (_event) {
      Googlemaps_Map.openedInfo = null;
    });
  };

  Googlemaps_Map.setForm = function (form) {
    return this.form = form;
  };

  Googlemaps_Map.load = function (selector, options) {
    if (!options) {
      options = {}
    }

    if (options["zoom"]) {
      if (Googlemaps_Map.validateZoom(options["zoom"])) {
        Googlemaps_Map.zoom = options["zoom"];
      }
    }
    if (options["center"]) {
      if (Googlemaps_Map.validateLatLon(options["center"][1], options["center"][0])) {
        Googlemaps_Map.center = options["center"].reverse();
      }
    }
    if (options["showGoogleMapsSearch"]) {
      Googlemaps_Map.showGoogleMapsSearch = true;
    }

    var center = Googlemaps_Map.getCenter();
    var mapOptions = {
      center: new google.maps.LatLng(center[0], center[1]),
      zoom: Googlemaps_Map.getZoom(),
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      panControl: false,
      zoomControl: true,
      zoomControlOptions: {
        style: google.maps.ZoomControlStyle.LARGE
      },
      mapTypeControl: true,
      scaleControl: true,
      scrollwheel: true,
      streetViewControl: true,
      overviewMapControl: true,
      overviewMapControlOptions: {
        opened: true
      }
    };
    Googlemaps_Map.map = new google.maps.Map($(selector).get(0), mapOptions);
  };

  Googlemaps_Map.getCenter = function () {
    return (Googlemaps_Map.center ? Googlemaps_Map.center : Googlemaps_Map.defaultCenter);
  }

  Googlemaps_Map.getZoom = function () {
    return (Googlemaps_Map.zoom ? Googlemaps_Map.zoom : Googlemaps_Map.defaultZoom);
  }

  Googlemaps_Map.resize = function () {
    google.maps.event.trigger(this.map, "resize");
    if (!this.resized) {
      var center = Googlemaps_Map.getCenter();
      this.map.setCenter(new google.maps.LatLng(center[0], center[1]));
      if (this.form) {
        this.form.renderMarkers();
      }
    }
    return this.resized = true;
  };

  Googlemaps_Map.renderMarkers = function () {
    if (this.form) {
      return this.form.renderMarkers();
    }
  };

  Googlemaps_Map.renderEvents = function () {
    if (this.form) {
      return this.form.renderEvents();
    }
  };

  Googlemaps_Map.setMarkers = function (markers, opts = {}) {
    let markerBounds;
    Googlemaps_Map.markers = markers;
    markerBounds = new google.maps.LatLngBounds();

    Object.entries(Googlemaps_Map.markers).forEach(([id, value]) => {
      const position = new google.maps.LatLng(value["loc"][1], value["loc"][0]);
      const markerOpts = {
        position: position,
        map: Googlemaps_Map.map,
        icon: value["image"] || Googlemaps_Map.markerIcon
      };

      Googlemaps_Map.markers[id]["marker"] = new google.maps.Marker(markerOpts);
      markerBounds.extend(position);

      let markerHtml = "";
      if (value['html']) {
        markerHtml = value['html'];
      } else if (value['name'] || value['text']) {
        const $markerContent = $("<div/>", { class: "marker marker-info" });
        if (value['name']) {
          $markerContent.append($("<p/>", { class: "marker-name" }).text(value['name']));
        }
        if (value['text']) {
          const $explanation = $("<div/>", { class: "marker-explanation" });
          value['text'].split(/[\r\n]+/).forEach(line => {
            if (/^https?:\/\//.test(line)) {
              $explanation.append($("<p/>", { class: "marker-link" }).html($("<a />", { href: line }).text(line)));
            } else {
              $explanation.append($("<p/>").text(line));
            }
          });
          $markerContent.append($explanation);
        }
        markerHtml = $markerContent.html();
      }

      if (Googlemaps_Map.showGoogleMapsSearch) {
        markerHtml += Googlemaps_Map.getMapsSearchHtml(value['loc'][1], value['loc'][0]);
      }

      if (markerHtml) {
        Googlemaps_Map.markers[id]["window"] = new google.maps.InfoWindow({
          content: markerHtml,
          pixelOffset: new google.maps.Size(0, 0),
        });
        Googlemaps_Map.attachMessage(id);
      }
    });

    if (opts['markerCluster']) {
      Googlemaps_Map.renderMarkerCluster();
    }
    Googlemaps_Map.adjustMarkerBounds(Object.keys(Googlemaps_Map.markers).length, markerBounds);
  };

  Googlemaps_Map.renderMarkerCluster = function () {
    const clusterMarkers = Object.values(Googlemaps_Map.markers).map(data => data.marker);
    Googlemaps_Map.markerClusterer = new MarkerClusterer(Googlemaps_Map.map, clusterMarkers, {
      // averageCenter: true,
      ignoreHiddenMarkers: true,
      imagePath: '/assets/img/marker-clusterer/m',
      // zoomOnClick: false,
    });

    google.maps.event.addListener(Googlemaps_Map.map, 'zoom_changed', () => {
      Googlemaps_Map.closeMarkerClusterInfo();
    });

    ClusterIcon.prototype.triggerClusterClick = function(event) {
      const cluster = this.cluster_;
      const markers = cluster.getMarkers();
      const positions = markers.map(marker => marker.position.toUrlValue());

      const clusterMarkers = Object.values(Googlemaps_Map.markers).filter(marker =>
        positions.includes([marker.loc[1], marker.loc[0]].toString())
      );
      const contents = clusterMarkers.map(marker => marker.html || "");
      const infoWindow = new google.maps.InfoWindow({
        content: `<div class="marker-cluster-info">${contents.join('')}</div>`,
        position: markers[0].position,
        pixelOffset: new google.maps.Size(0, -15),
        markerType: 'cluster', // custom parameter
      });

      Googlemaps_Map.openMarkerClusterInfo(infoWindow);
      event.stopPropagation();
    };
  };

  Googlemaps_Map.openMarkerClusterInfo = function (infoWindow) {
    if (Googlemaps_Map.openedInfo) {
      Googlemaps_Map.openedInfo.close();
    }
    Googlemaps_Map.openedInfo = infoWindow;

    infoWindow.open({
      map: Googlemaps_Map.map,
    });
  };

  Googlemaps_Map.closeMarkerClusterInfo = function () {
    if (Googlemaps_Map.openedInfo && Googlemaps_Map.openedInfo.markerType === 'cluster') {
      Googlemaps_Map.openedInfo.close();
    }
  };

  Googlemaps_Map.setKmlLayer = function (url) {
    Googlemaps_Map.kmlLayer = new google.maps.KmlLayer({
      url: url,
      suppressInfoWindows: true,
      preserveViewport: false
    });
    Googlemaps_Map.kmlLayer.setMap(Googlemaps_Map.map);
  };

  Googlemaps_Map.setGeoJson = function (url) {
    Googlemaps_Map.map.data.setStyle({
      fillColor: "#b2c9e8",
      strokeColor: "#5A88C6",
      strokeWeight: 1
    });
    Googlemaps_Map.map.data.loadGeoJson(url, {}, function(data) {
      var bounds = new google.maps.LatLngBounds();
      var locs = [];

      data.forEach(function (feature) {
        feature.getGeometry().forEachLatLng(function (LatLng) {
          bounds.extend(LatLng);
          locs.push(LatLng);
        });
      });

      Googlemaps_Map.adjustMarkerBounds(locs.length, bounds);
    });
  };

  Googlemaps_Map.adjustMarkerBounds = function(pointCount, bounds) {
    if (pointCount > 0) {
      // marker exists
      // set manually options or do fit
      var manuallyAdjust = false;
      var idleAdjuster = function() {};

      if (Googlemaps_Map.center) {
        var center = Googlemaps_Map.getCenter();
        Googlemaps_Map.map.setCenter(new google.maps.LatLng(center[0], center[1]));
        manuallyAdjust = true;
      }

      if (Googlemaps_Map.zoom) {
        Googlemaps_Map.map.setZoom(Googlemaps_Map.getZoom());
        manuallyAdjust = true;
      }

      if (!manuallyAdjust) {
        idleAdjuster = function() {
          if (Googlemaps_Map.map.getZoom() > Googlemaps_Map.getZoom()) {
            Googlemaps_Map.map.setZoom(Googlemaps_Map.getZoom());
          }
        };
        Googlemaps_Map.map.fitBounds(bounds);
      }
      google.maps.event.addListenerOnce(Googlemaps_Map.map, "idle", idleAdjuster);
    } else {
      // marker not exists
      // set manually or default options
      var center = Googlemaps_Map.getCenter();
      Googlemaps_Map.map.setCenter(new google.maps.LatLng(center[0], center[1]));
      Googlemaps_Map.map.setZoom(Googlemaps_Map.getZoom());
    }
  };

  Googlemaps_Map.validateZoom = function (zoom) {
    if (zoom >= 1 && zoom <= 21) {
      return true;
    } else {
      return false;
    }
  };

  Googlemaps_Map.validateLatLon = function (lat, lon) {
    if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      return true;
    } else {
      return false;
    }
  };

  Googlemaps_Map.getMapsSearchHtml = function(lat, lng) {
    const url = `${Googlemaps_Map.mapsSearchUrl}${lat},${lng}`;
    return `<p class="marker-link"><a href="${url}">Googleマップで確認する</a></p>`;
  };

  return Googlemaps_Map;
})();
