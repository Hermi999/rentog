/* Tell jshint that there exists a global called "gon" */
/* globals gon, prettyPrint */
/* jshint unused: false */

window.ST = window.ST || {};


window.ST.poolTool = function() {

  function init(){
    initializeCheckOrientation();
    initializeGantt();
    initializeDatepicker();
    initialize_poolTool_createTransaction_form(gon.locale, gon.choose_employee_or_renter_msg);
    initialize_device_picker();
  }


  function initializeDatepicker(){
    if (gon.locale !== 'en') {
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

    // Get booked dates for
    // Set the first listing as checked and initialize datepicker with the booked dates of this listing
    var booked_dates = [];
    $('input:radio[name=listing_id]:first').attr('checked',true);
    var listing_id = parseInt($('input[name=listing_id]:checked', '#poolTool_form').val());
    for(var y=0; y<gon.devices.length; y++){
      if(gon.devices[y].listing_id === listing_id){
        booked_dates = gon.devices[y].already_booked_dates;
        break;
      }
    }

    var picker = window.ST.initializeFromToDatePicker('datepicker', booked_dates);

    // If listing changes, then also update the booked dates in the datepicker
    $("input[name=listing_id]:radio").change(function () {
      var booked_dates = [];
      var listing_id = parseInt($('input[name=listing_id]:checked', '#poolTool_form').val());

      for(var y=0; y<gon.devices.length; y++){
        if(gon.devices[y].listing_id === listing_id){
          booked_dates = gon.devices[y].already_booked_dates;
          break;
        }
      }
      $('#start-on').val('');
      $('#end-on').val('');
      $('#datepicker').datepicker('remove');
      window.ST.initializeFromToDatePicker('datepicker', booked_dates);
      $('#datepicker').datepicker('update');
    });
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
          availability: gon.open_listings[j].availability,
          listing_id: gon.open_listings[j].listing_id,
          values: [{
            from: "/Date(" + today_ms + ")/",
            to: "/Date(" + next_month_ms + ")/",
            customClass: "ganttHidden"
          }]
        });
      }
    }
    source = source.concat(empty_arr);

    // If source is still empty (because company has no open listings),
    // then add dummy listings
    if (source.length < 1) {
      source = addDummyListings();
    }

    // Add hidden gantt-element, to show the chart at least until today + 1 month
    var hiddenElement = {
      values: [{
        from: "/Date(" + today_minus_3_ms + ")/",
        to: "/Date(" + next_month_ms + ")/",
        customClass: "ganttHidden"
      }]
    };
    source.push(hiddenElement);

    // Create gon.source, so that we can access the source when adding an element to one device
    gon.source = source;

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
      /*onItemClick: function(data) {
      },
      onAddClick: function(dt, rowId) {
      },
      onRender: function() {
      }*/
    });

    prettyPrint();
  }

  function initialize_device_picker(){
    $('.pooltool_grid_item_modifier_class').on('vclick', function(ev){
      ev.preventDefault();
      if(ev.currentTarget.nextElementSibling && ev.currentTarget.nextElementSibling.className === "radiobutton_griditem"){
        ev.currentTarget.nextElementSibling.firstElementChild.checked = true;
      }
    });
  }

  function initializeCheckOrientation(){
    window.addEventListener("orientationchange", function() {
        check_orientation();
    });
    check_orientation();
  }

  var check_orientation = function() {
      if(typeof window.orientation === 'undefined' || (gon.devices.length + gon.open_listings.length) === 0 ) {
          //not a mobile or no open listings
          return true;
      }
      if(Math.abs(window.orientation) !== 90 && $(window).width() < 600) {
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

  var addDummyListings = function(){
    var today = new Date();

    var from1_ms = Math.round(new Date(new Date(today).setDate(today.getDate()-3)).getTime());
    var to1_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+5)).getTime());

    var from2_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+1)).getTime());
    var to2_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+7)).getTime());
    var from3_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+9)).getTime());
    var to3_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+16)).getTime());
    var from4_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+23)).getTime());
    var to4_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+32)).getTime());

    var from5_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+3)).getTime());
    var to5_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+10)).getTime());
    var from6_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+16)).getTime());
    var to6_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+25)).getTime());
    var from7_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+30)).getTime());
    var to7_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+40)).getTime());

    return [
        {
          name: "Test Device 1",
          desc: "intern",
          values: [{
            from: "/Date(" + from1_ms + ")/",
            to: "/Date(" + to1_ms + ")/",
            label: "Renting Organization 1",
            customClass: "gantt_ownEmployee"
          }]
        },
        {
          name: "Test Device 2",
          desc: "trusted",
          values: [
            {
              from: "/Date(" + from2_ms + ")/",
              to: "/Date(" + to2_ms + ")/",
              label: "Renting Organization 4",
              customClass: "gantt_trustedCompany"
            },
            {
              from: "/Date(" + from3_ms + ")/",
              to: "/Date(" + to3_ms + ")/",
              label: "Renting Organization 2",
              customClass: "gantt_ownEmployee"
            },
            {
              from: "/Date(" + from4_ms + ")/",
              to: "/Date(" + to4_ms + ")/",
              label: "Renting Organization 7",
              customClass: "gantt_trustedCompany"
            }
          ]
        },
        {
          name: "Test Device 3",
          desc: "all",
          values: [
            {
              from: "/Date(" + from5_ms + ")/",
              to: "/Date(" + to5_ms + ")/",
              label: "Renting Organization 9",
              customClass: "gantt_anyCompany"
            },
            {
              from: "/Date(" + from6_ms + ")/",
              to: "/Date(" + to6_ms + ")/",
              label: "Renting Organization 7",
              customClass: "gantt_ownEmployee"
            },
            {
              from: "/Date(" + from7_ms + ")/",
              to: "/Date(" + to7_ms + ")/",
              label: "Renting Organization 7",
              customClass: "gantt_trustedCompany"
            }
          ]
        }
    ];
  };

  return {
    init: init
  };
};
