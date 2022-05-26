[![GitHub version](https://badge.fury.io/gh/gmaps-marker-clusterer%2Fgmaps-marker-clusterer.svg)](https://badge.fury.io/gh/gmaps-marker-clusterer%2Fgmaps-marker-clusterer) [![npm version](https://badge.fury.io/js/gmaps-marker-clusterer.svg)](https://badge.fury.io/js/gmaps-marker-clusterer) [![License](https://img.shields.io/badge/license-APACHE2-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](http://creativecommons.org/licenses/by-sa/4.0/)



**Please note:** This is a fork of the js-marker-clusterer library, the original repository can be found here https://github.com/googlemaps/js-marker-clusterer

![Logo](https://cdn.rawgit.com/gmaps-marker-clusterer/gmaps-marker-clusterer/master/gmaps-marker-clusterer-logo.svg)

# Gmaps Marker Clusterer

**A JavaScript API utility library for Google Maps**

A Google Maps JavaScript API v3 library to create and manage per-zoom-level clusters for large amounts of markers.

[Reference documentation](https://gmaps-marker-clusterer.github.io/gmaps-marker-clusterer/)

Migrated from the [Google Maps JavaScript API utility libraries on Google Code](https://code.google.com/p/google-maps-utility-library-v3/).

## Usage

Download or clone `markerclusterer.js` and images `m1.png` to `m5.png`, save images in `images` folder.

To use your own custom cluster images just name your images `m[1-5].png` or set the `imagePath` option to the location and name of your images like this: `imagePath: 'customImages/cat'` for images `cat1.png` to `cat5.png`.

index.html

```
<div id="map-container"><div id="map"></div></div>
<script src="markerclusterer.js"></script>
<script>
    function initialize() {
        var center = new google.maps.LatLng(51.5074, 0.1278);

        var map = new google.maps.Map(document.getElementById('map'), {
          zoom: 3,
          center: center,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        });

        var markers = [];
        var marker = new google.maps.Marker({
            position: new google.maps.LatLng(51.5074, 0.1278)
        });
        markers.push(marker);

        var options = {
            imagePath: 'images/m'
        };

        var markerCluster = new MarkerClusterer(map, markers, options);
    }

    google.maps.event.addDomListener(window, 'load', initialize);
</script>
```

### Custom CSS

Customize the cluster pins by using the `cssClass`-option.

#### Adding a custom CSS-Class `custom-pin` to the options:

```
var center = new google.maps.LatLng(37.4419, -122.1419),
    map = new google.maps.Map(document.getElementById('map'), {
        zoom: 3,
        center: center,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }),
    markers = [],
    options = {
        cssClass: 'custom-pin'
    };

for (var i = 0; i < 100; i++) {
    var dataPhoto = data.photos[i];
    var latLng = new google.maps.LatLng(dataPhoto.latitude,
        dataPhoto.longitude);
    var marker = new google.maps.Marker({
    position: latLng
    });
    markers.push(marker);
}

var markerCluster = new MarkerClusterer(map, markers, options);
```

#### Add your custom styles:

```
.custom-pin {
    height: 1em;
    line-height: 1;
    width: 1em;
    padding: .7em;
    text-align: center;
    cursor: pointer;
    color: white;
    background: black;
    position: absolute;
    border-radius: .5em;
    font-size: 1em;
    font-weight: bold;
    transition: all 500ms;
}

.custom-pin::after {
    content: '';
    border-width: 1em .5em;
    border-color: black transparent transparent transparent;
    border-style: solid;
    position: absolute;
    top: 99%;
    left: calc(50% - .5em);
}

.custom-pin:hover {
    transform: scale(1.15);
}
```

Have a look at the [custom-css example](examples/custom-css_example.html).

## Live Demos

[![Marker Clusterer Screenshot](https://googlemaps.github.io/js-marker-clusterer/screenshot.png)](https://gmaps-marker-clusterer.github.io/gmaps-marker-clusterer/#examples)

[Examples page](https://gmaps-marker-clusterer.github.io/gmaps-marker-clusterer/#examples)

## License

All code is licensed under Apache 2.0. See [LICENSE](LICENSE)-File.

The gmaps-marker-clusterer Logo is licensed under [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/).
[![CC BY-SA 4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
