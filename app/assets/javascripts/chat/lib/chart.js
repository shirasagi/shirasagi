this.Chat_Chart = (function() {
  function Chat_Chart() {}

  Chat_Chart.drawBar = function(selector) {
    $(selector).each(function(){
      var dataColumns = $.parseJSON($(this).attr("data-columns"));
      var labels = dataColumns[0];
      var data = dataColumns[1];
      var borderColor = [dataColumns[2]];

      new Chart(this, {
        type: 'bar',
        data: {
          labels: labels,
          datasets: [
            {
              type: 'line',
              label: $(this).attr("data-name"),
              data: data,
              borderColor : borderColor,
              fill: false
             },
           ],
        },
        options: {
          responsive: true,
          scales: {
            yAxes: [{
              ticks: {
                stepSize: 1
              },
            }],
          }
        }
      });
    });
  };

  Chat_Chart.drawPie = function(selector) {
    $(selector).each(function(){
      var dataColumns = $.parseJSON($(this).attr("data-columns"));
      var labels = [];
      var data = [];
      var backgroundColor = [];

      $.each(dataColumns, function(i,column) {
        labels.push(column[0]);
        data.push(column[1]);
        backgroundColor.push(column[2]);
      });

      new Chart(this, {
        type: 'pie',
        data: {
          labels: labels,
          datasets: [{
            data: data,
            backgroundColor: backgroundColor,
            borderWidth: 1
          }],
        },
        options: {
          responsive: true
        }
      });
    });
  };

  return Chat_Chart;

})();
