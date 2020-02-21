//= require chart.js/dist/Chart.min.js

this.Inquiry_Chart = (function() {
  function Inquiry_Chart() {}

  Inquiry_Chart.drawBar = function(selector) {
    $(selector).each(function(){
      var dataColumns = $.parseJSON($(this).attr("data-columns"));
      var labels = [];
      var data = [];
      var backgroundColor = [];
      var borderColor = [];

      $.each(dataColumns, function(k,v) {
        labels.push(k);
        data.push(v);
        backgroundColor.push('rgba(54, 162, 235, 0.2)');
        borderColor.push('rgba(54, 162, 235, 1)');
      });

      new Chart(this, {
        type: 'horizontalBar',
        data: {
          labels: labels,
          datasets: [{
            data: data,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: 1
          }],
        },
        options: {
          scales: {
            xAxes: [{
              ticks: { min: 0, max: 100, stepSize: 10 }
            }],
          },
          legend: {
            display: false
          }
        }
      });
    });
  };

  return Inquiry_Chart;

})();
