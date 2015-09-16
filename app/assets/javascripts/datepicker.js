window.ST = window.ST || {};

(function(module) {

  module.initializeFromToDatePicker = function(rangeCongainerId, booked_dates, tf_start_on, tf_end_on, booking_start_output, booking_end_output, start_today) {
    var now = new Date();
    var dateRage = $(rangeCongainerId);
    var dateLocale = dateRage.data('locale');
    var today = null;

    if (start_today){
      var today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    }

    var options = {
      calendarWeeks: true,
      startDate: today,
      autoclose: true,
      todayHighlight: true,
      inputs: [$(tf_start_on), $(tf_end_on)],
      daysOfWeekDisabled: ["0","6"],
      //datesDisabled: booked_dates,
      beforeShowDay: function(date) {
        // Already booked dates paint red
        for (var i=0; i<booked_dates.length; i++){
          var lock_date = new Date(booked_dates[i]);
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
    var picker = dateRage.datepicker(options);

    // Remove old event listeners
    $(tf_start_on).unbind('changeDate');
    $(tf_start_on).unbind('keyDown');
    $(tf_end_on).unbind('keyDown');
    picker.unbind('changeDate');

    // Define what to do with end date when start Date is picked
    $(tf_start_on).on('changeDate', function(selected){
      // Set Start Date of "end-on" datepicker
        if (selected.date){
          var startDate = new Date(selected.date.valueOf());
          var aktEndDate = $(tf_end_on).datepicker('getDate') || new Date("2099");
          startDate.setDate(startDate.getDate(new Date(selected.date.valueOf())));
          $(tf_end_on).datepicker('setStartDate', startDate);

        // set end date of "end-on" datepicker, based on next booked dates
          var endDate = new Date("2099/01/01");
          var lock;
          for (var i=0; i<booked_dates.length; i++){
            var lock_date = new Date(booked_dates[i]);
            if (startDate <= lock_date && lock_date < endDate){
              lock = true;
              endDate = lock_date;
            }
          }
          if (lock){
            $(tf_end_on).datepicker('setEndDate', endDate);
            if (aktEndDate > endDate){
              $(tf_end_on).datepicker('setDate', startDate);
            }
          }else{
            $(tf_end_on).datepicker('setEndDate', new Date("2099/01/01"));
          }
        }
      });

    // Do not allow manual input
    $(tf_start_on).keydown(function(e){
      e.preventDefault();
    });
    $(tf_end_on).keydown(function(e){
      e.preventDefault();
    });

    var outputElements = {
      "booking-start-output": $(booking_start_output),
      "booking-end-output": $(booking_end_output)
    };

    picker.on('changeDate', function(e) {
      var newDate = e.dates[0];
      if (newDate){
        var outputElementId = $(e.target).data("output");
        var outputElement = outputElements[outputElementId];
        outputElement.val(module.utils.toISODate(newDate));
      }
    });

    return picker;
  };
})(window.ST);
