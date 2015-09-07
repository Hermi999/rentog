/* Tell jshint that there exists a global called "gon" */
/* globals gon, prettyPrint */
/* jshint unused: false */

window.ST = window.ST || {};


window.ST.poolTool = function() {

  function init(){
    initializeCheckOrientation();
    initializeGantt();
    initializeFormular();
    initializeDatepicker();
  }


  function initializeFormular(){
    button = $('#addNewBooking');
    button.on('vclick', function(ev){
      if (button.html() === 'Abort'){
        $('#addNewBookingForm').fadeOut();
        button.html('Add new booking');
        button.addClass('primary-button');
        button.removeClass('delete-button');
      } else {
        $('#addNewBookingForm').fadeIn();
        button.html('Abort');
        button.removeClass('primary-button');
        button.addClass('delete-button');
      }
    });
  }

  function initializeDatepicker(){
    if (gon.locale === 'en') {
      return;
    }

    $.fn.datepicker.dates[gon.locale] = {
      days: gon.translated_days,
      daysShort: gon.translated_days_short,
      daysMin: gon.translated_days_min,
      months: gon.translated_months,
      monthsShort: gon.translated_months_short,
      today: gon.today,
      weekStart: gon.week_start,
      clear: gon.clear,
      format: gon.format
    };
  }


  function initializeGantt(){

    var source = gon.devices;
    var today = new Date();
    var today_ms = Math.round(today.getTime());
    var today_minus_3 = new Date(new Date(today).setMonth(today.getMonth()-3));
    var today_minus_3_ms = Math.round(today_minus_3.getTime());
    var next_month = new Date(new Date(today).setMonth(today.getMonth()+1));
    var next_month_ms = Math.round(next_month.getTime());

    // Add listings which have no transaction yet
    var empty_arr = [];
    for (var j=0; j<gon.open_listings.length; j++){
      var already_there = false;
      for (var k=0; k<source.length; k++){
        if (gon.open_listings[j].name === source[k].name){
          already_there = true;
        }
      }
      if (!already_there){
        empty_arr.push({
          name: gon.open_listings[j].name,
          desc: gon.open_listings[j].desc,
          //desc: "No bookings",
          values: [{
            from: "/Date(" + today_ms + ")/",
            to: "/Date(" + next_month_ms + ")/",
            customClass: "ganttHidden"
          }]
        });
      }
    }
    source = source.concat(empty_arr);


    // Add hidden gantt-element, to show the chart at least until today + 1 month
    var hiddenElement = {
      values: [{
        from: "/Date(" + today_minus_3_ms + ")/",
        to: "/Date(" + next_month_ms + ")/",
        customClass: "ganttHidden"
      }]
    };
    source.push(hiddenElement);


    $(".gantt").gantt({
      dow: gon.translated_days_min,
      months: gon.translated_months,
      navigate: "scroll",
      minScale: "days",
      itemsPerPage: 10,
      scrollToToday: true,
      holidays: ["/Date(1334872800000)/","/Date(1335823200000)/"],
      /* Get them from here: http://kayaposoft.com/enrico/json/*/
      source: source,
      onItemClick: function(data) {
        //alert("Item clicked - show some details");
      },
      onAddClick: function(dt, rowId) {
        // If clicked in one of the fields
        if (rowId !== ""){

        }
      },
      onRender: function() {
      }
    });

    prettyPrint();
  }


  function initializeCheckOrientation(){
    window.addEventListener("orientationchange", function() {
        check_orientation();
    });
    check_orientation();
  }

  var check_orientation = function() {
      if(typeof window.orientation == 'undefined') {
          //not a mobile
          return true;
      }
      if(Math.abs(window.orientation) != 90 && $(window).width() < 600) {
          //portrait mode
          $('#orr').fadeIn().bind('touchstart', function(e) {
              e.preventDefault();
          });
          return false;
      }
      else {
          //landscape mode
          $('#orr').fadeOut();
          return true;
      }
    };


  return {
    init: init
  };
};
