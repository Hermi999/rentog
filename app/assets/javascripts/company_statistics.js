/* Tell jshint that there exists a global called gon */
/* globals gon, getUrlParameter, console, google, $ */
/* jshint unused: false */

window.ST = window.ST || {};

window.ST.companyStatistics = (function() {
  function init(){
    var averageDeviceBookingPeriod_arr = gon.data.averageDeviceBookingPeriod || [];
    var peopleWithMostBookings_arr     = gon.data.peopleWithMostBookings || [];
    var peopleWithMostBookedDays_arr   = gon.data.peopleWithMostBookedDays || [];
    var devicesWithMostBookings_arr    = gon.data.devicesWithMostBookings || [];
    var devicesWithMostBookedDays_arr  = gon.data.devicesWithMostBookedDays || [];
    var bookingCompanyUnits_arr        = gon.data.bookingCompanyUnits || [];
    var deviceLivetime_arr             = gon.data.deviceLivetime || [];
    var userDeviceRelationship_arr     = gon.data.userDeviceRelationship || [];
    var deviceBookingDensityPerDay_arr = gon.data.deviceBookingDensityPerDay || [];


    if (averageDeviceBookingPeriod_arr.length <= 1){
      $('#noDataYet').show();
      return;
    }

    // Load Charts and the corechart package.
    google.charts.load('current', {'packages':['corechart','calendar', 'timeline', 'sankey']});

    // Callback that draws the pie chart for the averageDeviceBookingPeriod
    function averageDeviceBookingPeriod() {
      var data = google.visualization.arrayToDataTable(averageDeviceBookingPeriod_arr);

        var options = {
          height: 400,
          backgroundColor: "#f9e7d5",
          histogram: {bucketSize: 3},
          hAxis: {
            title: gon.averageDeviceBookingPeriod_hAxis_title,
            minValue: 0,
          },
          vAxis: {
            title: gon.averageDeviceBookingPeriod_vAxis_title,
            minValue: 0,
          },
          legend: {position: 'none'},
        };
        var chart = new google.visualization.Histogram(document.getElementById('g-chart-averageDeviceBookingPeriod'));
        chart.draw(data, options);
    }

    // Callback that draws the pie chart for the peopleWithMostBookings
    function peopleWithMostBookings(){
      var data = google.visualization.arrayToDataTable(peopleWithMostBookings_arr);
      var height = 100 + 20*peopleWithMostBookings_arr.length;

      var options = {
        height: height,
        backgroundColor: "#f9e7d5",
        chartArea: {width: '65%'},
        isStacked: true,
        hAxis: {
          title: gon.peopleWithMostBookings_hAxis_title,
          minValue: 0,
        }
      };
      var chart = new google.visualization.BarChart(document.getElementById('g-chart-peopleWithMostBookings'));
      chart.draw(data, options);
    }

    // Callback that draws the pie chart for the peopleWithMostBookedDays
    function peopleWithMostBookedDays(){
      var data = google.visualization.arrayToDataTable(peopleWithMostBookedDays_arr);
      var height = 100 + 20*peopleWithMostBookedDays_arr.length;

      var options = {
        backgroundColor: "#f9e7d5",
        height: height,
        chartArea: {width: '65%'},
        isStacked: true,
        hAxis: {
          title: gon.peopleWithMostBookedDays_hAxis_title,
          minValue: 0,
        }
      };
      var chart = new google.visualization.BarChart(document.getElementById('g-chart-peopleWithMostBookedDays'));
      chart.draw(data, options);
    }

    // Callback that draws the pie chart for the devicesWithMostBookings
    function devicesWithMostBookings(){
      var data = google.visualization.arrayToDataTable(devicesWithMostBookings_arr);
      var height = 100 + 20*devicesWithMostBookings_arr.length;

      var options = {
        backgroundColor: "#f9e7d5",
        height: height,
        chartArea: {width: '65%'},
        isStacked: true,
        hAxis: {
          title: gon.devicesWithMostBookings_hAxis_title,
          minValue: 0,
        }
      };
      var chart = new google.visualization.BarChart(document.getElementById('g-chart-devicesWithMostBookings'));
      chart.draw(data, options);
    }

    // Callback that draws the pie chart for the devicesWithMostBookedDays
    function devicesWithMostBookedDays(){
      var data = google.visualization.arrayToDataTable(devicesWithMostBookedDays_arr);
      var height = 100 + 20*devicesWithMostBookedDays_arr.length;

      var options = {
        backgroundColor: "#f9e7d5",
        height: height,
        chartArea: {width: '65%'},
        isStacked: true,
        hAxis: {
          title: gon.devicesWithMostBookedDays_hAxis_title,
          minValue: 0,
        }
      };
      var chart = new google.visualization.BarChart(document.getElementById('g-chart-devicesWithMostBookedDays'));
      chart.draw(data, options);
    }

    // Callback that draws the pie chart for the bookingCompanyUnits
    function bookingCompanyUnits(){
      var data = google.visualization.arrayToDataTable(bookingCompanyUnits_arr);

      var options = {
        backgroundColor: "#f9e7d5",
        chartArea: {width: '65%'},
        height: 400,
        vAxis: {title: gon.bookingCompanyUnits_hAxis_title},
        hAxis: {title: gon.bookingCompanyUnits_yAxis_title},
        seriesType: 'bars',
        series: {5: {type: 'line'}}
      };

      var chart = new google.visualization.ComboChart(document.getElementById('g-chart-bookingCompanyUnits'));
        chart.draw(data, options);
      }

    // Callback that draws the pie chart for the deviceLivetime
    function deviceLivetime(){
      var container = document.getElementById('g-chart-deviceLivetime');
      var chart = new google.visualization.Timeline(container);
      var dataTable = new google.visualization.DataTable();

      dataTable.addColumn({ type: 'string', id: 'Devicename' });
      dataTable.addColumn({ type: 'date', id: 'Start' });
      dataTable.addColumn({ type: 'date', id: 'End' });

      var rows = [];
      deviceLivetime_arr.forEach(function(el){
        rows.push([ el[0], new Date(el[1]), new Date(el[2]) ]);
      });

      dataTable.addRows(rows);

      var height = 100 + 35*deviceLivetime_arr.length;
      var options = {
        backgroundColor: "#f9e7d5",
        height: height
      };

      chart.draw(dataTable, options);
    }

    // Callback that draws the pie chart for the userDeviceRelationship
    function userDeviceRelationship() {
      var data = new google.visualization.DataTable();
      data.addColumn('string', 'User');
      data.addColumn('string', 'Device');
      data.addColumn('number', gon.userDeviceRelationship_column_title);
      data.addRows(userDeviceRelationship_arr);

      var height = 100 + 40*userDeviceRelationship_arr.length;
      var options = {
        backgroundColor: "#f9e7d5",
        height: height
      };

      // Instantiates and draws our chart, passing in some options.
      var chart = new google.visualization.Sankey(document.getElementById('g-chart-userDeviceRelationship'));
      chart.draw(data, options);
    }

    // Callback that draws the pie chart for the deviceBookingDensityPerDay
    function deviceBookingDensityPerDay() {
      var dataTable = new google.visualization.DataTable();
      dataTable.addColumn({ type: 'date', id: 'Date' });
      dataTable.addColumn({ type: 'number', id: 'Won/Loss' });

      var rows = [], lowest_year=3000, highest_year=0;
      deviceBookingDensityPerDay_arr.forEach(function(el){
        var _date = new Date(el[0]);
        rows.push([ _date, el[1] ]);

        if(lowest_year > _date.getYear()){
          lowest_year = _date.getYear();
        }
        if(highest_year < _date.getYear()){
          highest_year = _date.getYear();
        }

      });

      dataTable.addRows(rows);

      var chart = new google.visualization.Calendar(document.getElementById('g-chart-deviceBookingDensityPerDay'));

      var height = 150 + (highest_year - lowest_year)*120;
      var options = {
        backgroundColor: "#f9e7d5",
        height: height,
        calendar: { cellSize: 13 },
      };
      chart.draw(dataTable, options);
    }

    // Draw the charts
    google.charts.setOnLoadCallback(averageDeviceBookingPeriod);
    google.charts.setOnLoadCallback(deviceBookingDensityPerDay);
    google.charts.setOnLoadCallback(peopleWithMostBookings);
    google.charts.setOnLoadCallback(peopleWithMostBookedDays);
    google.charts.setOnLoadCallback(devicesWithMostBookings);
    google.charts.setOnLoadCallback(devicesWithMostBookedDays);
    google.charts.setOnLoadCallback(bookingCompanyUnits);
    google.charts.setOnLoadCallback(deviceLivetime);
    google.charts.setOnLoadCallback(userDeviceRelationship);
  }

  return {
    init: init
  };
})();
