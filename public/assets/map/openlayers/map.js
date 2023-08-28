this.Openlayers_Map = (function () {
  function Openlayers_Map(canvas, opts) {
    if (opts == null) {
      opts = {};
    }
    this.canvas = canvas;
    this.opts = opts;

    if (opts["zoom"] && this.validateZoom(opts["zoom"])) {
      this.zoom = opts["zoom"];
    }
    this.defaultZoom = Openlayers_Map.defaultZoom;

    if (opts["center"] && this.validateLatLon(opts["center"][1], opts["center"][0])) {
      this.center = opts["center"];
    }
    this.defaultCenter = Openlayers_Map.defaultCenter.reverse();

    this.showGoogleMapsSearch = false;
    if (opts["showGoogleMapsSearch"]) {
      this.showGoogleMapsSearch = opts["showGoogleMapsSearch"];
    }

    this.markerFeature = null;
    this.markerLayer = null;
    this.popup = null;
    this.markerIcon = Openlayers_Map.markerIcon;
    this.loadedLayers = [];
    this.render();
  }

  Openlayers_Map.defaultCenter = [36.204824, 138.252924];

  Openlayers_Map.defaultZoom = 10;

  Openlayers_Map.markerIcon = "/assets/img/googlemaps/marker1.png";

  Openlayers_Map.clickIcon = "/assets/img/googlemaps/marker17.png";

  Openlayers_Map.prototype.getCenter = function () {
    return (this.center ? this.center : this.defaultCenter);
  };

  Openlayers_Map.prototype.getZoom = function () {
    return (this.zoom ? this.zoom : this.defaultZoom);
  };

  Openlayers_Map.prototype.render = function () {
    this.initMap();
    this.initPopup();
    if (this.opts["markers"]) {
      this.renderMarkers(this.opts["markers"]);
    }
    this.resize();
    this.renderEvents();
  };

  Openlayers_Map.prototype.createLayers = function (layerOpts) {
    var i, layer, layers, len, opts, projection, source, url;
    layers = [];
    for (i = 0, len = layerOpts.length; i < len; i++) {
      opts = layerOpts[i];
      source = opts["source"];
      url = opts["url"];
      projection = opts["projection"];
      layer = new ol.layer.Tile({
        source: new ol.source[source]({
          url: url,
          projection: projection
        })
      });
      layers.push(layer);
    }
    return layers;
  };

  Openlayers_Map.prototype.initMap = function () {
    var layerOpts;

    layerOpts = this.opts['layers'];
    layerOpts || (layerOpts = [
      {
        source: "XYZ",
        url: "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png",
        projection: "EPSG:3857"
      }
    ]);
    this.map = new ol.Map({
      target: this.canvas,
      renderer: ['canvas', 'dom'],
      layers: this.createLayers(layerOpts),
      controls: ol.control.defaults({
        attributionOptions: {
          collapsible: false
        }
      }),
      view: new ol.View({
        projection: "EPSG:3857",
        center: ol.proj.transform(this.getCenter(), "EPSG:4326", "EPSG:3857"),
        maxZoom: 18,
        zoom: this.getZoom()
      }),
      logo: true
    });
  };

  Openlayers_Map.prototype.initPopup = function () {
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
    this.popup.find('.closer').on('click', (function (_this) {
      return function (e) {
        _this.popupOverlay.setPosition(void 0);
        $(_this).blur();
        return false;
      };
    })(this));
  };

  Openlayers_Map.prototype.showPopup = function (feature, coordinate) {
    var markerHtml;
    markerHtml = feature.get("markerHtml");
    if (!markerHtml) {
      this.popup.hide();
      return;
    }
    this.popup.find('.content').html(markerHtml);
    this.popup.show();
    this.popupOverlay.setPosition(coordinate);
  };

  Openlayers_Map.prototype.renderEvents = function () {
    this.map.on('click', (function (_this) {
      return function (e) {
        var feature;
        feature = _this.map.forEachFeatureAtPixel(e.pixel, function (feature, layer) {
          return feature;
        });
        if (feature) {
          _this.showPopup(feature, e.coordinate);
        }
      };
    })(this));
  };

  Openlayers_Map.prototype.createMarkerStyle = function (iconSrc) {
    return new ol.style.Style({
      image: new ol.style.Icon({
        anchor: [0.5, 1],
        anchorXUnits: 'fraction',
        anchorYUnits: 'fraction',
        src: iconSrc
      })
    });
  };

  Openlayers_Map.prototype.setMarker = function (loc, opts) {
    var feature, iconSrc, pos, style;
    if (opts == null) {
      opts = {};
    }
    iconSrc = this.markerIcon;
    if (opts['image']) {
      iconSrc = opts['image'];
    }
    style = this.createMarkerStyle(iconSrc);
    pos = [loc[1], loc[0]];

    feature = new ol.Feature({
      geometry: new ol.geom.Point(ol.proj.transform(pos, "EPSG:4326", "EPSG:3857")),
      markerId: opts['id'],
      markerHtml: opts['html'],
      category: opts['category']
    });
    feature.setStyle(style);
    if (!this.markerLayer) {
      this.markerLayer = new ol.layer.Vector({
        source: new ol.source.Vector({
          features: [feature]
        })
      });
      this.map.addLayer(this.markerLayer);
    } else {
      this.markerLayer.getSource().addFeature(feature);
    }
    return feature;
  };

  Openlayers_Map.prototype.getMarker = function (markerId) {
    var ret, source;
    ret = null;
    if (!this.markerLayer) {
      return ret;
    }
    source = this.markerLayer.getSource();
    source.forEachFeature(function (feature) {
      if (feature.get("markerId") === markerId) {
        return ret = feature;
      }
    });
    return ret;
  };

  Openlayers_Map.prototype.getMarkers = function () {
    var features, source;
    source = this.markerLayer.getSource();
    features = source.getFeatures();
    return features;
  };

  Openlayers_Map.prototype.removeMarkers = function () {
    var source;
    if (this.popup) {
      this.popup.hide();
    }
    if (this.markerLayer) {
      source = this.markerLayer.getSource();
      source.forEachFeature(function (feature) {
        source.removeFeature(feature);
      });
    }
  };

  Openlayers_Map.prototype.setCenter = function (pos) {
    return this.map.getView().setCenter(ol.proj.transform(pos, 'EPSG:4326', 'EPSG:3857'));
  };

  Openlayers_Map.prototype.setZoom = function (level) {
    return this.map.getView().setZoom(level);
  };

  Openlayers_Map.prototype.renderMarkers = function (markers) {
    var feature, iconSrc, id, marker, markerHtml, name, pos, style, text;

    for (id = 0; id < markers.length; id++) {
      marker = markers[id];
      iconSrc = marker['image'] || this.markerIcon || '/assets/img/openlayers/marker1.png';
      style = this.createMarkerStyle(iconSrc);

      name = marker['name'];
      text = marker['html'] || marker['text'];
      pos = [marker['loc'][0], marker['loc'][1]];

      markerHtml = "";
      if (name) {
        markerHtml += '<p>' + name + '</p>';
      }
      if (text) {
        $.each(text.split(/[\r\n]+/), function () {
          if (this.match(/^https?:\/\//)) {
            markerHtml += '<p><a href="' + this + '">' + this + '</a></p>';
          } else {
            markerHtml += '<p>' + this + '</p>';
          }
        });
      }
      if (this.showGoogleMapsSearch) {
        markerHtml += Googlemaps_Map.getMapsSearchHtml(pos[1], pos[0]);
      }

      feature = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.transform(pos, "EPSG:4326", "EPSG:3857")),
        markerId: marker['id'],
        markerHtml: markerHtml,
        iconSrc: iconSrc,
        category: marker['category']
      });
      feature.setStyle(style);
      if (!this.markerLayer) {
        this.markerLayer = new ol.layer.Vector({
          source: new ol.source.Vector()
        });
        this.map.addLayer(this.markerLayer)
      }
      this.markerLayer.getSource().addFeature(feature)
    }
  };

  Openlayers_Map.prototype.resize = function () {
    if (!this.markerLayer) {
      return;
    }

    var markerLength = this.markerLayer.getSource().getFeatures().length;
    if (markerLength >= 0) {
      // marker exists
      // set manually options and do fit
      var extent = this.markerLayer.getSource().getExtent();
      this.map.getView().fit(extent, this.map.getSize());

      if (markerLength == 1) {
        this.map.getView().setZoom(this.getZoom());
      }
      if (this.center) {
        this.setCenter(this.getCenter());
      }
      if (this.zoom) {
        this.setZoom(this.getZoom());
      }
    } else {
      // marker not exists
      // set manually or default options
      this.setCenter(this.getCenter());
      this.setZoom(this.getZoom());
    }
  };

  Openlayers_Map.prototype.loadLayer = function (url, olFormat) {
    var _self = this;
    var _url = url;
    var _olFormat = olFormat;

    // https://openlayers.org/en/latest/apidoc/module-ol_source_Vector.html
    var vectorSource = new ol.source.Vector({
      format: new _olFormat(),
      loader: function(extent, resolution, projection) {
        var proj = projection.getCode();
        var xhr = new XMLHttpRequest();
        var onError = function() {
          console.warn("loadLayer error:" + url);
        }
        xhr.open('GET', _url);
        xhr.onerror = onError;
        xhr.onloadstart = function() {
          $(_self.canvas).hide();
        }
        xhr.onload = function() {
          if (xhr.status == 200) {
            var feature = new _olFormat().
              readFeatures(xhr.responseText, { featureProjection: projection });
            vectorSource.addFeatures(feature);

            extent = layer.getSource().getExtent();
            $(_self.canvas).show();
            _self.map.getView().fit(extent, _self.map.getSize());
            if (_self.map.getView().getZoom() > _self.opts.zoom) {
              _self.map.getView().setZoom(_self.opts.zoom);
            }
          } else {
            onError();
          }
        }
        xhr.send();
      },
      //strategy: ol.loadingstrategy.bbox
    });
    var layer = new ol.layer.Vector({
      source: vectorSource
    });
    this.map.addLayer(layer);
    this.loadedLayers.push(layer);
  };

  Openlayers_Map.prototype.validateZoom = function (zoom) {
    if (zoom >= 3 && zoom <= 18) {
      return true;
    } else {
      return false;
    }
  };

  Openlayers_Map.prototype.validateLatLon = function (lat, lon) {
    if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      return true;
    } else {
      return false;
    }
  };

  Openlayers_Map.prototype.removeloadedLayers = function () {
    var _self = this;
    $.each(this.loadedLayers, function () {
      _self.map.removeLayer(this);
    });
  };

  return Openlayers_Map;
})();
