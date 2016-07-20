/* globals google */

window.ST = window.ST || {};

window.ST.initializeKpis = function(kpis_weeks, kpis_months) {
  google.charts.load('current', {'packages':['line']});

  function draw(kpis, id, title){

    function drawChart() {
      var data = new google.visualization.DataTable();
      for (var i in kpis[0]) {
        if (i === "0"){
          data.addColumn('string', kpis[0][i]);
        }else{
          data.addColumn('number', kpis[0][i]);
        }
      }
      kpis.splice(0,1);
      data.addRows(kpis);

      var options = {
        chart: {
          title: title,
          curveType: 'function',
          legend: { position: 'right' }
        },
        width: 900,
        height: 500
      };

      var chart = new google.charts.Line(document.getElementById(id));

      chart.draw(data, options);
    }

    google.charts.setOnLoadCallback(drawChart);
  }

  draw(kpis_weeks, "linechart_material_weeks", "Rentog Key Performance Indicators - 7 day steps");
  draw(kpis_months, "linechart_material_months", "Rentog Key Performance Indicators - 30 day steps");
};
