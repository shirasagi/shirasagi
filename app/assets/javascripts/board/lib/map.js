// Used Openlayers 3
// Document: http://openlayers.org/en/v3.12.1/apidoc/
// Sample: http://maps.gsi.go.jp/development/sample.html
this.Board_Map = (function () {
  function Board_Map(canvas, opts) {
    if (opts == null) {
      opts = {};
    }
    this.canvas = canvas;
    this.opts = opts;
    this.markerFeature = null;
    this.markerLayer = null;
    this.popup = null;
    this.render();
  }

  Board_Map.prototype.render = function () {
    var center;
    center = this.opts['center'] || this.opts['marker'] || [138.252924, 36.204824];
    this.map = new ol.Map({
      target: this.canvas,
      renderer: ['canvas', 'dom'],
      layers: [
        new ol.layer.Tile({
          source: new ol.source.XYZ({
            url: "http://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png",
            projection: "EPSG:3857"
          })
        })
      ],
      controls: ol.control.defaults({
        attributionOptions: {
          collapsible: false
        }
      }),
      view: new ol.View({
        projection: "EPSG:3857",
        center: ol.proj.transform(center, "EPSG:4326", "EPSG:3857"),
        maxZoom: 18,
        zoom: this.opts['zoom'] || 10
      }),
      logo: false
    });
    if (this.opts['gps']) {
      this.setMarkerFromGps();

    }
    if (this.opts['marker']) {
      this.setMarker(this.opts['marker']);

    }
    if (this.opts['popup']) {
      this.initPopup();

    }
    if (!this.opts['readonly']) {
      return this.map.on('click', (function (_this) {
        return function (e) {
          var pos;
          pos = ol.proj.transform(e.coordinate, "EPSG:3857", "EPSG:4326");
          while (pos[0] < 180) {
            pos[0] += 360;
          }
          while (pos[0] > 180) {
            pos[0] -= 360;
          }
          return _this.setMarker(pos);
        };
      })(this));
    }
  };

  Board_Map.prototype.initPopup = function () {
    $("body").append('<div id="marker-popup"><div class="closer"></div><div class="content"></div></div>');
    this.popup = $('#marker-popup');
    this.popup.hide();
    this.popupOverlay = new ol.Overlay({
      element: this.popup.get(0),
      autoPan: true,
      autoPanAnimation: {
        duration: 250
      }
    });
    this.map.addOverlay(this.popupOverlay);
    this.map.on('click', (function (_this) {
      return function (e) {
        return _this.showPopup(e);
      };
    })(this));
    this.map.on('pointermove', (function (_this) {
      return function (e) {
        var cursor, hit, pixel;
        if (e.dragging) {
          _this.popup.hide();
          return;
        }
        pixel = _this.map.getEventPixel(e.originalEvent);
        hit = _this.map.hasFeatureAtPixel(pixel);
        cursor = hit ? 'pointer' : '';
        return _this.map.getTarget().style.cursor = cursor;
      };
    })(this));
    return this.popup.find('.closer').on('click', (function (_this) {
      return function (e) {
        _this.popupOverlay.setPosition(void 0);
        $(_this).blur();
        return false;
      };
    })(this));
  };

  Board_Map.prototype.showPopup = function (evt) {
    var feature, markerId;
    feature = this.map.forEachFeatureAtPixel(evt.pixel, function (feature, layer) {
      return feature;
    });
    if (!feature) {
      this.popup.hide();
      return;
    }
    markerId = feature.get("markerId");
    if (!markerId) {
      this.popup.hide();
      return;
    }
    this.popup.find('.content').html($("#marker-html-" + markerId).html());
    this.popup.show();
    return this.popupOverlay.setPosition(evt.coordinate);
  };

  Board_Map.prototype.setMarker = function (position, opts) {
    var ref, src, style;
    if (opts == null) {
      opts = {};
    }
    if (!this.markerFeature) {
      src = '/assets/img/map-marker.png';
      if (this.opts['image']) {
        src = this.opts['image'];
      }
      style = new ol.style.Style({
        image: new ol.style.Icon({
          anchor: [0.5, 1],
          anchorXUnits: 'fraction',
          anchorYUnits: 'fraction',
          src: src
        })
      });
      this.markerFeature = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.transform(position, "EPSG:4326", "EPSG:3857")),
        markerId: (ref = opts['markerId']) != null ? ref : null
      });
      this.markerFeature.setStyle(style);
    } else {
      this.markerFeature.setGeometry(new ol.geom.Point(ol.proj.transform(position, "EPSG:4326", "EPSG:3857")));
    }
    if (!this.markerLayer) {
      this.markerLayer = new ol.layer.Vector({
        source: new ol.source.Vector({
          features: [this.markerFeature]
        })
      });
      this.map.addLayer(this.markerLayer);
    }
    return $(this.canvas).trigger('position:set', {
      position: position,
      zoom: this.map.getView().getZoom()
    });
  };

  Board_Map.prototype.addMarker = function (position, opts) {
    var feature, layer, ref, src, style;
    if (opts == null) {
      opts = {};
    }
    src = '/assets/img/map-marker.png';
    if (opts['image']) {
      src = opts['image'];
    }
    style = new ol.style.Style({
      image: new ol.style.Icon({
        anchor: [0.5, 1],
        anchorXUnits: 'fraction',
        anchorYUnits: 'fraction',
        src: src
      })
    });
    feature = new ol.Feature({
      geometry: new ol.geom.Point(ol.proj.transform(position, "EPSG:4326", "EPSG:3857")),
      markerId: (ref = opts['markerId']) != null ? ref : null
    });
    feature.setStyle(style);
    layer = new ol.layer.Vector({
      source: new ol.source.Vector({
        features: [feature]
      })
    });
    return this.map.addLayer(layer);
  };

  Board_Map.prototype.resetMarker = function () {
    var source;
    if (this.markerLayer) {
      source = this.markerLayer.getSource();
      source.forEachFeature(function (feature) {
        return source.removeFeature(feature);
      });
      this.map.removeLayer(this.markerLayer);
      this.markerFeature = null;
      this.markerLayer = null;
    }
    return $(this.canvas).trigger('position:unset');
  };

  Board_Map.prototype.setMarkerFromGps = function () {
    if (!navigator.geolocation) {
      return;
    }
    return navigator.geolocation.getCurrentPosition((function (_this) {
      return function (position) {
        return _this.setMarker([position.coords.longitude, position.coords.latitude]);
      };
    })(this));
  };

  return Board_Map;

})();

