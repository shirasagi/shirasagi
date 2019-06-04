this.Chat_Chart = (function() {
  function Chat_Chart() {}

  Chat_Chart.drawBar = function(selector) {
    $(selector).each(function(){
      var dataColumns = $.parseJSON($(this).attr("data-columns"));
      var labels = [];
      var data = [];
      var backgroundColor = [];

      $.each(dataColumns, function(i,column) {
        console.log(column);
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
