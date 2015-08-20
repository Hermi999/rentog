window.ST = window.ST || {};

(function(module) {

  module.initializeFromToDatePicker = function(rangeCongainerId) {
    var now = new Date();
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    var dateRage = $('#'+ rangeCongainerId);
    var dateLocale = dateRage.data('locale');
    var locked_dates = ["08/26/2015", "08/27/2015"];

    var options = {
      calendarWeeks: true,
      //todayHighlight: true,
      startDate: today,
      autoclose: true,
      inputs: [$("#start-on"), $("#end-on")],
      daysOfWeekDisabled: ["0","6"],
      datesDisabled: locked_dates,
      beforeShowDay: function(date) {
        // Already booked dates paint red
        for (var i=0; i<locked_dates.length; i++){
          lock_date = new Date(locked_dates[i]);
          if (date.getYear() === lock_date.getYear() && date.getMonth() === lock_date.getMonth() && date.getDate() === lock_date.getDate()){
            return "red";
          }
        }

        // Hide past dates
        if (date < today){
          return "hidden_date"
        }

        // All other paint green
        return "green";
      },
      language: dateLocale
    };


    // Initialize Datepicker on dateRange and give event handler
    var picker = dateRage.datepicker(options)
      .on('changeDate', function(e){
          // wah: ToDo
          e.preventDefault();
          return false;
      });;

    var outputElements = {
      "booking-start-output": $("#booking-start-output"),
      "booking-end-output": $("#booking-end-output")
    };

    picker.on('changeDate', function(e) {
      var newDate = e.dates[0];
      var outputElementId = $(e.target).data("output");
      var outputElement = outputElements[outputElementId];
      outputElement.val(module.utils.toISODate(newDate));
    });
  };
})(window.ST);
