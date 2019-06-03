this.Chat_Chart = (function() {
  function Chat_Chart() {}

  Chat_Chart.drawBar = function(selector) {
    $(selector).each(function(){
      var dataColumns = $.parseJSON($(this).attr("data-columns"));
      var labels = [];
      var data = [];
      var backgroundColor = [];
      var borderColor = [];

      $.each(dataColumns, function(i,column) {
        console.log(column);
        labels.push(column[0]);
        data.push(column[1]);
        backgroundColor.push('rgba(54, 162, 235, 0.2)');
        borderColor.push('rgba(54, 162, 235, 1)');
      });

      new Chart(this, {
        type: 'pie',
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
        }
      });
    });
  };

  return Chat_Chart;

})();
