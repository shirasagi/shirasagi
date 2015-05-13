class @Chart
  @load: (callback)->
    google.load('visualization', '1.0', { 'packages' : ['corechart'] })
    google.setOnLoadCallback(callback)

  @drawBar: (selector, data) ->
    array = [["", "", { type: "string", role: "tooltip" }]]
    for k, v of data
      array.push([k, v, "#{v}%"])
    array = google.visualization.arrayToDataTable(array)
    chart = new google.visualization.BarChart($(selector).get(0))
    options = {
      hAxis: { viewWindow: { min: 0, max: 100 } },
      legend: { position: "none" }
    }
    chart.draw(array, options)
