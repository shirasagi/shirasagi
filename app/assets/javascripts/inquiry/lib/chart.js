this.Chart = (function() {
    function Chart() {}

  Chart.load = function(callback) {
    google.load('visualization', '1.0', {
    'packages': ['corechart']
  });
  return google.setOnLoadCallback(callback);
};

Chart.drawBar = function(selector, data) {
  var array, chart, k, options, v;
array = [
  [
    "", "", {
    type: "string",
    role: "tooltip"
  }
  ]
];
for (k in data) {
  v = data[k];
array.push([k, v, v + "%"]);
}
array = google.visualization.arrayToDataTable(array);
chart = new google.visualization.BarChart($(selector).get(0));
options = {
  hAxis: {
    viewWindow: {
      min: 0,
      max: 100
    }
  },
  legend: {
    position: "none"
  }
};
return chart.draw(array, options);
};

return Chart;

})();
