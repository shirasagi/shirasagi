//= require chart.js/dist/chart.js
//= require chartjs-plugin-datalabels/dist/chartjs-plugin-datalabels.js

this.Inquiry2_Chart = (function() {
  function Inquiry2_Chart() {}

  Inquiry2_Chart.drawBar = function(selector) {
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
        type: 'bar',
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
          indexAxis: 'y',
          plugins: {
            legend: {
              display: false
            }
          },
          scales: {
            x: {
              min: 0,
              max: 100,
              ticks: {
                stepSize: 10
              }
            },
          }
        }
      });
    });
  };

  return Inquiry2_Chart;

})();
