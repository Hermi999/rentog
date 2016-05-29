window.ST = window.ST || {};

(function(module) {

  module.set_datepicker_language = function(obj){
    if (obj.locale !== 'en') {
      $.fn.datepicker.dates[obj.locale] = {
        days: obj.translated_days,
        daysShort: obj.translated_days_short,
        daysMin: obj.translated_days_min,
        months: obj.translated_months,
        monthsShort: obj.translated_months_short,
        today: obj.today,
        weekStart: obj.week_start,
        clear: obj.clear,
        format: obj.format
      };
    }
  };

  module.initializeDatePickerWithBookings = function(rangeCongainerId, booked_dates, tf_start_on, tf_end_on, booking_start_output, booking_end_output, datepicker_start_date) {
    var dateRage = $(rangeCongainerId);
    var dateLocale = dateRage.data('locale');
    var start_date = datepicker_start_date || null;

    if(datepicker_start_date === "today"){
      start_date = new Date(new Date().setHours(1,0,0,0));
    }

    var options = {
      calendarWeeks: true,
      startDate: start_date,
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
        if (date < start_date){
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
    $(tf_start_on).off('changeDate');
    $(tf_start_on).off('keyDown');
    $(tf_end_on).off('keyDown');
    picker.off('changeDate');


    // Define what to do with end date when start Date is picked
    $(tf_start_on).on('changeDate', function(selected){
      // Set Start Date of "end-on" datepicker
        if (selected.date){
          var startDate = new Date(selected.date.valueOf());
          var aktEndDate = $(tf_end_on).datepicker('getDate') || new Date("2099");
          //startDate.setDate(startDate.getDate(new Date(selected.date.valueOf())));

          $(tf_end_on).datepicker('setStartDate', startDate);

          // If current end_date is before new start date, then set
          // end date to start date
          if (aktEndDate < startDate || aktEndDate > new Date("2098")){
            $(tf_end_on).datepicker('setDate', startDate);
          }else{
            // set end date of "end-on" datepicker, based on next booked dates
            var endDate = new Date("2099/01/01");
            var lock;
            // Get the nearest locked date next to the startDate
            for (var i=0; i<booked_dates.length; i++){
              var lock_date = new Date(booked_dates[i]);
              if (startDate <= lock_date && lock_date < endDate){
                lock = true;
                endDate = lock_date;
              }
            }
            if (lock){
              // Set maximal pickable date
              $(tf_end_on).datepicker('setEndDate', endDate);
              // Set end date to startDate if the current endDate is in the locked area
              if (aktEndDate > endDate){
                $(tf_end_on).datepicker('setDate', startDate);
              }
            }else{
              $(tf_end_on).datepicker('setEndDate', new Date("2099/01/01"));
            }
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
      // Add new date to hidden form elements
      var newDate = e.dates[0];
      if (newDate){
        var outputElementId = $(e.target).data("output");
        var outputElement = outputElements[outputElementId];
        outputElement.val(module.utils.toISODate(newDate));
      }
    });

    return picker;
  };

  module.initialize_datepicker = function(dateRange_id, tf_start_on_id, tf_end_on_id, date_end_output, date_start_output, datepicker_start_date){
    var dateRange = $(dateRange_id);
    var dateLocale = dateRange.data('locale');
    var start_date = datepicker_start_date || null;

    if(datepicker_start_date === "today"){
      start_date = new Date(new Date().setHours(1,0,0,0));
    }

    var options = {
      calendarWeeks: true,
      startDate: start_date,
      autoclose: true,
      todayHighlight: true,
      inputs: [$(tf_start_on_id), $(tf_end_on_id)],
      language: dateLocale
    };

    // Initialize Datepicker on dateRange
    var picker = dateRange.datepicker(options);


    // Define what to do with end date when start Date is picked
    $(tf_start_on_id).on('changeDate', function(selected){
      // Set Start Date of "end-on" datepicker
        if (selected.date){
          var startDate = new Date(selected.date.valueOf());
          var aktEndDate = $(tf_end_on_id).datepicker('getDate') || new Date("2099");
          //startDate.setDate(startDate.getDate(new Date(selected.date.valueOf())));

          $(tf_end_on_id).datepicker('setStartDate', startDate);

          // If current end_date is before new start date, then set
          // end date to start date
          if (aktEndDate < startDate || aktEndDate > new Date("2098")){
            $(tf_end_on_id).datepicker('setDate', startDate);
          }else{
            $(tf_end_on_id).datepicker('setEndDate', new Date("2099/01/01"));
          }
        }
      });

    // Do not allow manual input
    $(tf_start_on_id).keydown(function(e){
      e.preventDefault();
    });
    $(tf_end_on_id).keydown(function(e){
      e.preventDefault();
    });

    var outputElements = {};
    outputElements[date_start_output] = $("#" + date_start_output);
    outputElements[date_end_output] = $("#" + date_end_output);

    picker.on('changeDate', function(e) {
      // Add new date to hidden form elements
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
