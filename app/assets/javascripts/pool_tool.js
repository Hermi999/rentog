/* Tell jshint that there exists a global called "gon" */
/* globals gon, prettyPrint, initialize_poolTool_createTransaction_form, getDatesBetweenRange */
/* jshint unused: false */

window.ST = window.ST || {};


window.ST.poolTool = function() {

  function init(){
    initializeCheckOrientation();
    initializeGantt();
    initializeDatepicker();
    initialize_poolTool_createTransaction_form(gon.locale, gon.choose_employee_or_renter_msg);
    initialize_device_picker();

    // Initialize popover
    $(".inline").colorbox({inline:true, width:"90%", height:"95%", maxWidth:"600px", maxHeight:"450px"});
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
    $('input:radio[name=listing_id]:first').prop('checked',true);
    var listing_id = parseInt($('input[name=listing_id]:checked', '#poolTool_form').val());
    for(var y=0; y<gon.devices.length; y++){
      if(gon.devices[y].listing_id === listing_id){
        booked_dates = gon.devices[y].already_booked_dates;
        break;
      }
    }

    window.ST.initializeFromToDatePicker('#datepicker', booked_dates, '#start-on', '#end-on', "#booking-start-output", "#booking-end-output");
    window.ST.initializeFromToDatePicker('#datepicker2', booked_dates, '#start-on2', '#end-on2', "#booking-start-output2", "#booking-end-output2");

    // If listing changes, then also update the booked dates in the datepicker
    $("input[name=listing_id]:radio").change(function (ev) {
      var booked_dates = [];
      var listing_id = parseInt($('input[name=listing_id]:checked', '#poolTool_form').val());

      for(var y=0; y<gon.devices.length; y++){
        if(gon.devices[y].listing_id === listing_id){
          booked_dates = gon.devices[y].already_booked_dates;
          break;
        }
      }

      // Re-initialize Datepickers
      $('#start-on').val('');
      $('#end-on').val('');
      $('#datepicker').datepicker('remove');

      // Slightly delay execution of Datepicker update, so that DOM is
      // immediately updated and UI with radio button change isn't stuck
      setTimeout(updateDatepicker(booked_dates), 1);
    });
  }

  function updateDatepicker(booked_dates){
    window.ST.initializeFromToDatePicker('#datepicker', booked_dates, '#start-on', '#end-on', "#booking-start-output", "#booking-end-output");
    $('#datepicker').datepicker('update');
  }
  function updateDatepicker2(booked_dates){
    window.ST.initializeFromToDatePicker('#datepicker2', booked_dates, '#start-on2', '#end-on2', "#booking-start-output2", "#booking-end-output2");
    $('#datepicker2').datepicker('update');
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

    updateGanttChart(source);

    prettyPrint();
  }

  function updateGanttChart(source){
    $(".gantt").gantt({
      dow: gon.translated_days_min,
      months: gon.translated_months,
      navigate: "scroll",
      minScale: "days",
      itemsPerPage: 100,
      scrollToToday: true,
      holidays: ["/Date(1334872800000)/","/Date(1335823200000)/"],
      /* Get them from here: http://kayaposoft.com/enrico/json/*/
      source: source,
      onItemClick: function(data) {
        var info = data.data("dataObj");
        var regEx = /\d+/;
        var s = new Date(parseInt(info.booking.from.match(regEx)));
        var e = new Date(parseInt(info.booking.to.match(regEx)));
        var booked_dates = [];
        var listing_id = parseInt(info.listing.listing_id);
        var transaction_id = parseInt(info.booking.transaction_id);

        // Update shown information in popover
        $('#poolTool_popover_deviceName').html(info.listing.name);
        $('#poolTool_popover_renter').html(info.booking.label);
        $('#poolTool_popover_availability').html(info.listing.availability);

        // Open Popover
        $('#modifyBookingLink').click();

        // Re-initialize Datepickers with booked dates
        for(var y=0; y<gon.devices.length; y++){
          if(gon.devices[y].listing_id === listing_id){
            // Copy array, because we do not want to get our source changed
            booked_dates = gon.devices[y].already_booked_dates.slice();
            break;
          }
        }

        // Remove booked_dates from this transaction
        for(var yy=0; yy<booked_dates.length; yy++){
          var dateArray = getDatesBetweenRange(s, e);

          for (var ii = 0; ii < dateArray.length; ii ++ ) {

            var yyyy = dateArray[ii].getFullYear();
            var mm = dateArray[ii].getMonth() + 1;
            var dd = dateArray[ii].getDate();

            if (mm < 10){
              mm = "0" + mm;
            }

            if (dd < 10){
              dd = "0" + dd;
            }

            dateArray[ii] = yyyy + "-" + mm + "-" + dd;

            if (booked_dates[yy] === dateArray[ii]){
              booked_dates.splice(yy, 1);
            }
          }
        }

        $('#start-on2').val('');
        $('#end-on2').val('');
        $('#datepicker2').datepicker('remove');

        // Slightly delay execution of Datepicker update, so that DOM is
        // immediately updated and UI with radio button change isn't stuck
        // setTimeout(updateDatepicker2(booked_dates), 1);
        updateDatepicker2(booked_dates);

        // Set datepicker dates to those from db
        $('#start-on2').datepicker('setDate', s);
        $('#end-on2').datepicker('setDate', e);

        // Disable buttons if booking is external
        if (info.booking.customClass === "gantt_anyCompany" ||
            info.booking.customClass === "gantt_anyEmployee" ||
            info.booking.customClass === "gantt_trustedCompany"){
          $('#btn_update').prop('disabled', true);
          $('#btn_delete').prop('disabled', true);
          $('#btn_update').css('opacity', 0.6);
          $('#btn_delete').css('opacity', 0.6);
        }else{
          $('#btn_update').prop('disabled', false);
          $('#btn_delete').prop('disabled', false);
          $('#btn_update').css('opacity', 1);
          $('#btn_delete').css('opacity', 1);
        }

        // Store button text
        var btn_update_text = $('#btn_update').html();
        var btn_delete_text = $('#btn_delete').html();

        // Remove old event listeners
        $('#btn_update').unbind();
        $('#btn_delete').unbind();

        // Remove booking from pool tool & db
        $('#btn_delete').on('vclick', function(){
          var result = window.confirm(gon.deleteConfirmation);

          if (result){
            // Add event listeners for remove booking from db
            $.ajax({
              method: "post",   // Browser can't do delete requests
              dataType: "json",
              url: "/" + gon
              .locale + "/" + gon.p_id + "/transactions/" + transaction_id,
              data: {_method:'delete'},
              beforeSend :function(){
                // Disable Sumbmit Buttons
                $("#btn_update").prop('disabled', true);
                $("#btn_delete").prop('disabled', true);
                $('#btn_update').css('opacity', 0.6);
                $('#btn_delete').css('opacity', 0.6);
                var _jqxhr = jQuery.getJSON('https://s3.eu-central-1.amazonaws.com/rentog/assets/locales/' + gon.locale + '.json', function(json) {
                  $("#btn_update").html(json.please_wait);
                  $("#btn_delete").html(json.please_wait);
                });
              }
            })
              .success(function(ev){
                if (ev.status === "success"){
                  // Remove from pool tool
                  data.remove();
                }
                // Close popover
                $.colorbox.close();

                // Enable Submit button again
                setTimeout(function(){
                  $("#btn_update").prop('disabled', false);
                  $("#btn_update").html(btn_update_text);
                  $("#btn_delete").prop('disabled', false);
                  $("#btn_delete").html(btn_delete_text);
                  $('#btn_update').css('opacity', 1);
                  $('#btn_delete').css('opacity', 1);
                }, 200);
              })
              .error(function(){
                // Show error message and fade it out after some time
                $('#error_message').show();
                $('#error_message').fadeOut(8000);

                // Enable Submit button again
                $("#btn_update").prop('disabled', false);
                $("#btn_update").html(btn_update_text);
                $("#btn_delete").prop('disabled', false);
                $("#btn_delete").html(btn_delete_text);
                $('#btn_update').css('opacity', 1);
                $('#btn_delete').css('opacity', 1);
              });
          }
        });

        $('#btn_update').on('vclick', function(){
          var s_new = new Date($('#booking-start-output2').val());
          var e_new = new Date($('#booking-end-output2').val());

          $.ajax({
            method: "PUT",
            url: "/" + gon.locale + "/" + gon.p_id + "/transactions/" + transaction_id,
            data: {from: s_new, to: e_new},
            beforeSend: function(){
              // Disable Sumbmit Buttons
              $("#btn_update").prop('disabled', true);
              $("#btn_delete").prop('disabled', true);
              $('#btn_update').css('opacity', 0.6);
              $('#btn_delete').css('opacity', 0.6);
              var _jqxhr = jQuery.getJSON('https://s3.eu-central-1.amazonaws.com/rentog/assets/locales/' + gon.locale + '.json', function(json) {
                $("#btn_update").html(json.please_wait);
                $("#btn_delete").html(json.please_wait);
              });
            }
          })
            .success(function(data){
              if (data.status === "success"){
                // update gantt view
                for(var x=0; x<source.length; x++){
                  if(source[x].listing_id === listing_id){
                    for(var y=0; y<source[x].values.length; y++){
                      if(source[x].values[y].transaction_id === transaction_id){
                        source[x].values[y].from = "/Date(" + Math.round(s_new.getTime()) + ")/";
                        source[x].values[y].to = "/Date(" + Math.round(e_new.getTime()) + ")/";
                        x = source.length;
                        break;
                      }
                    }
                  }
                }
                gon.source = source;
                updateGanttChart(gon.source);
              }
              else{
                // Show error message and fade it out after some time
                var received_msg = data.message || "";
                var msg = $('#error_message').html();
                $('#error_message').html(msg + " " + received_msg);
                $('#error_message').show();
                $('#error_message').fadeOut(8000);
                // Reset shown error message
                setTimeout(function(){
                  $('#error_message').html(msg);
                },8000);
              }

              // close popover
              $.colorbox.close();

              // Enable Submit button again
              setTimeout(function(){
                $("#btn_update").prop('disabled', false);
                $("#btn_update").html(btn_update_text);
                $("#btn_delete").prop('disabled', false);
                $("#btn_delete").html(btn_delete_text);
                $('#btn_update').css('opacity', 1);
                $('#btn_delete').css('opacity', 1);
              }, 200);
            })
            .error(function(){
              // Show error message and fade it out after some time
              $('#error_message').show();
              $('#error_message').fadeOut(8000);

              // Enable Submit button again
              $("#btn_update").prop('disabled', false);
              $("#btn_update").html(btn_update_text);
              $("#btn_delete").prop('disabled', false);
              $("#btn_delete").html(btn_delete_text);
              $('#btn_update').css('opacity', 1);
              $('#btn_delete').css('opacity', 1);
            });
        });
      },
      onAddClick: function(dt, rowId) {
        //console.log(dt);
        //console.log(rowId);
      },
      onRender: function() {
      }
    });
  }

  function initialize_device_picker(){
    $('.pooltool_grid_item_modifier_class').on('vclick', function(ev){
      ev.preventDefault();
      if(ev.currentTarget.nextElementSibling && ev.currentTarget.nextElementSibling.className === "radiobutton_griditem"){
        ev.currentTarget.nextElementSibling.firstElementChild.checked = true;
        $('#' + ev.currentTarget.nextElementSibling.firstElementChild.id).change();
        // Add styling to selected radio-image-element
        //$('.testabc').removeClass('testabc');
        //ev.currentTarget.firstChild.classList.add('testabc');
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
    init: init,
    updateGanttChart: updateGanttChart
  };
};
