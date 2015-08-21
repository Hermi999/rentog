window.ST = window.ST || {};

(function(module) {

  module.initializeFromToDatePicker = function(rangeCongainerId) {
    var now = new Date();
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    var dateRage = $('#'+ rangeCongainerId);
    var dateLocale = dateRage.data('locale');
    var locked_dates = ["08/26/2015", "08/27/2015","08/28/2015", "08/29/2015", "09/10/2015", "09/11/2015", "09/12/2015", "09/13/2015", "09/15/2015", "09/16/2015", "09/19/2015", "09/20/2015", "05/01/2016"];


    var options = {
      calendarWeeks: true,
      startDate: today,
      autoclose: true,
      inputs: [$("#start-on"), $("#end-on")],
      daysOfWeekDisabled: ["0","6"],
      //datesDisabled: locked_dates,
      beforeShowDay: function(date) {
        // Already booked dates paint red
        for (var i=0; i<locked_dates.length; i++){
          var lock_date = new Date(locked_dates[i]);
          if (date.getYear() === lock_date.getYear() && date.getMonth() === lock_date.getMonth() && date.getDate() === lock_date.getDate()){
            return "red";
          }
        }

        // Hide past dates
        if (date < today){
          return "hidden_date";
        }

        // All other paint green
        return "green";
      },
      language: dateLocale
    };


    // Initialize Datepicker on dateRange
    var picker = dateRage.datepicker(options)

    // Define what to do with end date when start Date is picked
    $("#start-on").on('changeDate', function(selected){
      // Set Start Date of "end-on" datepicker
        var startDate = new Date(selected.date.valueOf());
        var aktEndDate = $('#end-on').datepicker('getDate') || new Date("2099");
        startDate.setDate(startDate.getDate(new Date(selected.date.valueOf())));
        $('#end-on').datepicker('setStartDate', startDate);

      // set end date of "end-on" datepicker, based on next booked dates
        var endDate = new Date("2099/01/01");
        var lock;
        for (var i=0; i<locked_dates.length; i++){
          var lock_date = new Date(locked_dates[i]);
          if (startDate <= lock_date && lock_date < endDate){
            lock = true;
            endDate = lock_date;
          }
        }
        if (lock){
          $('#end-on').datepicker('setEndDate', endDate);
          if (aktEndDate > endDate){
            $('#end-on').datepicker('setDate', startDate);
          }
        }else{
          $('#end-on').datepicker('setEndDate', new Date("2099/01/01"));
        }
      });

    // Do not allow manual input
    $("#start-on").keydown(function(e){
      e.preventDefault();
    });
    $("#end-on").keydown(function(e){
      e.preventDefault();
    });

  };
})(window.ST);
