/* Tell jshint that there exists a global called "gon" */
/* globals gon, prettyPrint, initialize_poolTool_createTransaction_form, getDatesBetweenRange, Spinner, console */
/* jshint unused: false */

window.ST = window.ST || {};

if (typeof gon !== 'undefined'){
  window.ST.poolToolTheme  = gon.theme || "theme_dark";
}
window.ST.poolToolRows   = 0;
window.ST.poolToolImages = [];
var opts = {
  lines: 13,             // The number of lines to draw
  length: 0,             // The length of each line
  width: 20,             // The line thickness
  radius: 80,            // The radius of the inner circle
  scale: 1.25,           // Scales overall size of the spinner
  corners: 1,            // Corner roundness (0..1)
  color: '#904242',      // #rgb or #rrggbb or array of colors
  opacity: 0.05,         // Opacity of the lines
  rotate: 0,             // The rotation offset
  direction: 1,          // 1: clockwise, -1: counterclockwise
  speed: 1,              // Rounds per second
  trail: 60,             // Afterglow percentage
  fps: 20,               // Frames per second when using setTimeout() as a fallback for CSS
  zIndex: 2e9,           // The z-index (defaults to 2000000000)
  className: 'spinner',  // The CSS class to assign to the spinner
  top: '49%',            // Top position relative to parent
  left: '50%',           // Left position relative to parent
  shadow: false,         // Whether to render a shadow
  hwaccel: false,        // Whether to use hardware acceleration
  position: 'absolute'  // Element positioning
};
window.ST.pooToolSpinner = new Spinner(opts).spin();




window.ST.poolTool = function() {

  function init(){
    $('.page-content').append(window.ST.pooToolSpinner.el);
    fullScreen();
    initializeCheckOrientation();
    initializeGantt();
    initializeDatepicker();
    initialize_poolTool_createTransaction_form(gon.locale, gon.choose_employee_or_renter_msg);
    initialize_device_picker();
    initialize_poolTool_options();

    // Show devices the current logged in user has in his hands
    if (gon.pool_tool_preferences.pooltool_employee_has_to_give_back_device === true){
      show_my_devices();
    }


    // Initialize popover and remove buttons if employee is logged in
    if (gon.is_admin === false){
      $(".inline").colorbox({inline:true, width:"90%", height:"95%", maxWidth:"500px", maxHeight:"400px"});
    }
    else{
      $(".inline").colorbox({inline:true, width:"90%", height:"95%", maxWidth:"600px", maxHeight:"450px"});
    }
  }

  function show_my_devices(){
    remove_old_bookings(gon.user_active_bookings);

    for(var i=0; i<gon.user_active_bookings.length; i++){
      var title = gon.user_active_bookings[i].title;
      var start_on = gon.user_active_bookings[i].start_on;
      var end_on = gon.user_active_bookings[i].end_on;
      var transaction_id = gon.user_active_bookings[i].transaction_id;
      var image = "";

      if (gon.devices[i] && title === gon.devices[i].name){
        image = gon.devices[i].image;
      }


      $('#my_devices')
        .append($('<div class="user_booking" />')
          .append($('<div />')
            .append($('<p class="user_booking_header">')
              .html(title))
            .append('<img src="' + image + '" class="user_booking_img" />')
            .append($('<span class="return_on" />')
              .html('Return on: '))
            .append(end_on)
          )
          .append($('<button id="return_now_' + i + '" />')
            .html('Return now')
          )
        );

        // Store transaction_id with button
        $('#return_now_' + i).data('transaction_id', transaction_id);

      // On click on button
      // ATTENTION: Function in a loop. Do not use a reference from the outside
      // within that loop
      /*jshint -W083 */
      $('#return_now_'+ i).on('click', function(ev){
        console.log($('#' + ev.currentTarget.id).data('transaction_id'));
      });
    }
  }

  function remove_old_bookings(){
    for(var i=0; i<gon.user_active_bookings.length; i++){
      for(var j=i+1; j<gon.user_active_bookings.length; j++){
        if (gon.user_active_bookings[i].title === gon.user_active_bookings[j].title){
          if (gon.user_active_bookings[i].ends_on < gon.user_active_bookings[j].ends_on){
            gon.user_active_bookings.splice(i, 1);
          }else{
            gon.user_active_bookings.splice(j, 1);
          }
        }
      }
    }
  }


  function initialize_poolTool_options(){
    // Show only my bookings (the current user)
    $('.only_mine').prop('checked', false);

    $('.only_mine').on('change', function(){
      if($('.only_mine').prop('checked')){
        $('.bar').hide();
        $('.gantt_ownEmployee_me').show();
        $('.gantt_anyCompany_me').show();
        $('.gantt_trustedCompany_me').show();
        $('.gantt_otherReason_me').show();
      }else{
        $('.bar').show();
      }
    });

    $('#only_mine_label').on('click',function(ev){
      if ($('.only_mine').prop('checked')){
        $('.only_mine').prop('checked',false);
        $('.only_mine').change();
      }else{
        $('.only_mine').prop('checked',true);
        $('.only_mine').change();
      }
    });

    // Do not allow more than 249 chars for the description
    var desc_maxchars = 249;
    $('#ta_description').keyup(function () {
        var tlength = $(this).val().length;
        $(this).val($(this).val().substring(0, desc_maxchars));
        var tlength = $(this).val().length;
        remain = desc_maxchars - parseInt(tlength);
        $('#description_counter').html(remain);
    });

    // Do not allow more than 40 chars for the reason
    var reason_maxchars = 40;
    $('#tf_device_renter').keyup(function () {
        var tlength = $(this).val().length;
        remain = reason_maxchars - parseInt(tlength);
        $('#reason_counter').html(remain);
    });
  }


  function initialize_listing_previews(){
    for (var i = 0; i < window.ST.poolToolRows; i++) {

      // Function in a loop. Do not use i in there!
      /*jshint -W083 */
      $('#rowheader' + i).on('mouseover', function(ev){
        if (ev.currentTarget.firstChild.firstChild){
          var id = ev.currentTarget.id;
          var text = ev.currentTarget.firstChild.firstChild.data;
          var ii = parseInt(id.substr(9,1));
          var alreadyThere = false;

          if (gon.source[ii].image && gon.source[ii].name === text){
            for(var j=0; j<window.ST.poolToolImages.length; j++){
              if (ii === window.ST.poolToolImages[j]){
                alreadyThere = true;
              }
            }
            window.ST.poolToolImages.push(ii);

            if(alreadyThere){
              $('#rowheader_image' + ii).show();
            }else{
              var img = $('<img id="rowheader_image'+ ii +'" height="' + $(".spacer").height() + '"/>').attr('src', gon.source[ii].image)
                // Function in a loop. Do not use i in there!
                /*jshint -W083 */
                .on('load', function(){
                  if (!this.complete || typeof this.naturalWidth === "undefined" || this.naturalWidth === 0) {
                  } else {
                      $(".spacer").append(img);
                      img.show();
                  }
                });
            }
          }
        }
      });

      // Function in a loop. Do not use i in there.
      /*jshint -W083 */
      $('#rowheader'+i).on('mouseout', function(ev){
        var id = ev.currentTarget.id;
        var ii = parseInt(id.substr(9,1));

        $('#rowheader_image' + ii).hide();
      });
    }
  }


  function fullScreen(){
    $('.header-wrapper').addClass('fullscreen');
    $('.title-header-wrapper').addClass('fullscreen');
    $('.page-content .wrapper').addClass('fullscreen');
  }


  function initializeThemes(){
    var allThemes  = ["theme_dark", "theme_red", "theme_white"];
    var allClasses = ["gantt", "header_g", "row_g", "wd_g", "sa_g", "sn_g",
                      "today", "navigate", "fn-content", "legend", "dataPanel_past",
                      "gantt_otherReason", "ganttLegend_otherReason", "gantt_otherReason_me",
                      "gantt_ownEmployee", "ganttLegend_ownEmployee", "gantt_ownEmployee_me",
                      "gantt_anyEmployee", "ganttLegend_anyEmployee", "gantt_anyEmployee_me",
                      "gantt_anyCompany", "ganttLegend_anyCompany", "gantt_anyCompany_me",
                      "gantt_trustedCompany", "ganttLegend_trustedCompany","gantt_trustedCompany_me",
                      "nav-link", "showLegend", "load", "newBookingForm"];

    // Set default theme
    changeTheme(window.ST.poolToolTheme, allThemes, allClasses);
    $('#theme_dark').css('border', 'none');
    $('#theme_white').css('border', 'none');
    $('#theme_red').css('border', 'none');
    $('#' + window.ST.poolToolTheme).css('border', '2px solid black');

    $('#theme_dark').on('vclick', function(){
      changeTheme('theme_dark', allThemes, allClasses);
      $('#theme_dark').css('border', '2px solid black');
      $('#theme_white').css('border', 'none');
      $('#theme_red').css('border', 'none');
      window.ST.poolToolTheme = "theme_dark";
      saveTheme("theme_dark");
    });
    $('#theme_white').on('vclick', function(){
      changeTheme('theme_white', allThemes, allClasses);
      $('#theme_white').css('border', '2px solid black');
      $('#theme_dark').css('border', 'none');
      $('#theme_red').css('border', 'none');
      window.ST.poolToolTheme = "theme_white";
      saveTheme("theme_white");
    });
    $('#theme_red').on('vclick', function(){
      changeTheme('theme_red', allThemes, allClasses);
      $('#theme_red').css('border', '2px solid black');
      $('#theme_white').css('border', 'none');
      $('#theme_dark').css('border', 'none');
      window.ST.poolToolTheme = "theme_red";
      saveTheme("theme_red");
    });
  }

  function changeTheme(theme, allThemes, allClasses){
    for (var y=0; y<allClasses.length; y++){
      // remove old themes
      for (var i=0; i<allThemes.length; i++){
        $('.' + allClasses[y]).removeClass(allClasses[y] + '_' + allThemes[i]);
      }

      // add new theme
      $('.' + allClasses[y]).addClass(allClasses[y] + '_' + theme);
    }
  }

  function saveTheme(theme){
    $.ajax({
      method: "post",
      dataType: "json",
      url: "/" + gon.current_user_username + "/poolToolTheme",
      data: {theme: theme},
    })
    .success(function(data){
      // Do not show any message to user
      console.log(data);
    })
    .error(function(data){
      // Do not show any message to user
      console.log(data);
    });
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
    for(var y=0; y<gon.source.length; y++){
      if(gon.source[y].listing_id === listing_id){
        if (gon.source[y].already_booked_dates){
          booked_dates = gon.source[y].already_booked_dates;
        }
        break;
      }
    }

    window.ST.initializeFromToDatePicker('#datepicker', booked_dates, '#start-on', '#end-on', "#booking-start-output", "#booking-end-output");
    window.ST.initializeFromToDatePicker('#datepicker2', booked_dates, '#start-on2', '#end-on2', "#booking-start-output2", "#booking-end-output2");

    // If listing changes, then also update the booked dates in the datepicker
    $("input[name=listing_id]:radio").change(function (ev) {
      var booked_dates = [];
      var listing_id = parseInt($('input[name=listing_id]:checked', '#poolTool_form').val());

      for(var y=0; y<gon.source.length; y++){
        if(gon.source[y].listing_id === listing_id){
          if (gon.source[y].already_booked_dates){
            booked_dates = gon.source[y].already_booked_dates;
          }
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
    var next_month = new Date(new Date(today).setMonth(today.getMonth()+3));
    var next_month_ms = Math.round(next_month.getTime());

    // Add listings which have no transaction yet
    var empty_arr = [];
    for (var j=0; j<gon.open_listings.length; j++){
      var already_there = false;
      for (var k=0; k<source.length; k++){
        if (gon.open_listings[j].name === source[k].name){
          already_there = true;

          // copy image url
          source[k].image = gon.open_listings[j].image;
        }
      }

      if (!already_there){
        empty_arr.push({
          name: gon.open_listings[j].name,
          desc: gon.open_listings[j].desc,
          created_at: gon.open_listings[j].created_at,
          availability: gon.open_listings[j].availability,
          listing_id: gon.open_listings[j].listing_id,
          image: gon.open_listings[j].image,
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

    // Add hidden gantt-element, to show the chart at least until today + 3 months
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
      // wah todo: Add Holidays
      // Get them from here: http://kayaposoft.com/enrico/json/
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
        // Employee - Remove buttons if user is not company admin or rentog admin
        // and this is not a booking of the user
        if (gon.is_admin === false && info.booking.renter_id !== gon.current_user_id){
          $('#btn_update').css('display', 'none');
          $('#btn_delete').css('display', 'none');

          // Set dates with datepicker, because then we have the correct
          // format for the current language
          $('#start-on2').datepicker('setDate', s);
          $('#end-on2').datepicker('setDate', e);

          // Remove datepicker if employee is showing booking
          //$('#datepicker2').datepicker('remove');

          // Disable datepickers
          $('#start-on2').prop('disabled', true);
          $('#end-on2').prop('disabled', true);
        }
        else{
          $('#btn_update').css('display', 'block');
          $('#btn_delete').css('display', 'block');
          $('#start-on2').prop('disabled', false);
          $('#end-on2').prop('disabled', false);
        // Company admin
        // Re-initialize Datepickers with booked dates
          for(var y=0; y<source.length; y++){
            if(source[y].listing_id === listing_id){
              // Copy array, because we do not want to get our source changed
              if (source[y].already_booked_dates){
                booked_dates = source[y].already_booked_dates.slice();
              }
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
              if (mm < 10){ mm = "0" + mm; }
              if (dd < 10){ dd = "0" + dd; }
              dateArray[ii] = yyyy + "-" + mm + "-" + dd;

              if (booked_dates[yy] === dateArray[ii]){
                booked_dates.splice(yy, 1);
              }
            }
          }

          $('#start-on2').val('');
          $('#end-on2').val('');
          $('#datepicker2').datepicker('remove');
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
                url: "/" + gon.locale + "/" + gon.comp_id + "/transactions/" + transaction_id,
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

                    // Update source
                    var booked_d = [];
                    for(var x=0; x<source.length; x++){
                      if(source[x].listing_id === listing_id){
                        for(var y=0; y<source[x].values.length; y++){
                          if(source[x].values[y].transaction_id === transaction_id){
                            // Remove element from array
                            source[x].values.splice(y, 1);

                            // Remove also days from already booked dates
                            var dateArray = getDatesBetweenRange(s, e);
                            // Go through each booked day and remove it from
                            // the already booked dates
                            for (var ii = 0; ii < dateArray.length; ii ++ ) {
                              // Format for compare
                              var yyyy = dateArray[ii].getFullYear();
                              var mm = dateArray[ii].getMonth() + 1;
                              var dd = dateArray[ii].getDate();
                              if (mm < 10){ mm = "0" + mm; }
                              if (dd < 10){ dd = "0" + dd; }
                              var new_date = yyyy + "-" + mm + "-" + dd;


                              // New reference
                              booked_d = source[x].already_booked_dates;

                              // Compare and remove
                              for (var yy =0; yy < booked_d.length; yy++){
                                if (booked_d[yy] === new_date){
                                  booked_d.splice(yy, 1);
                                }
                              }
                            }

                            // Leave loops
                            x = source.length;
                            break;
                          }
                        }
                      }
                    }
                    gon.source = source;

                    // update datepicker
                    $('#start-on').val('');
                    $('#end-on').val('');
                    $('#datepicker').datepicker('remove');
                    updateDatepicker(booked_d);

                    // Update load factors without reloading --> work
                    /*
                    $.each(source, function (i, entry) {
                      var load = window.ST.poolTool().calculateLoadFactor(entry);

                      if(load){

                      }
                    });
                    */

                    // the other way...
                    updateGanttChart(gon.source);
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
              url: "/" + gon.locale + "/" + gon.comp_id + "/transactions/" + transaction_id,
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
                  // update gantt view & source
                  // Update datepicker
                      var booked_d;

                      for(var x=0; x<source.length; x++){
                        if(source[x].listing_id === listing_id){

                          // Update start and end date
                          for(var y=0; y<source[x].values.length; y++){
                            if(source[x].values[y].transaction_id === transaction_id){
                              source[x].values[y].from = "/Date(" + Math.round(s_new.getTime()) + ")/";
                              source[x].values[y].to = "/Date(" + Math.round(e_new.getTime()) + ")/";
                              break;
                            }
                          }

                          // New reference
                          booked_d = source[x].already_booked_dates;

                          // Get each booked day of current booking (transaction)
                          var dateArray_old = getDatesBetweenRange(s, e);
                          var dateArray_new = getDatesBetweenRange(s_new, e_new);

                          // Go through each booked day and remove it from
                          // the already booked dates
                          for (var ii = 0; ii < dateArray_old.length; ii ++ ) {
                            // Format for compare
                            var yyyy = dateArray_old[ii].getFullYear();
                            var mm = dateArray_old[ii].getMonth() + 1;
                            var dd = dateArray_old[ii].getDate();
                            if (mm < 10){ mm = "0" + mm; }
                            if (dd < 10){ dd = "0" + dd; }
                            var formated_date = yyyy + "-" + mm + "-" + dd;

                            // Remove old dates
                            for (var yy =0; yy < booked_d.length; yy++){
                              if (booked_d[yy] === formated_date){
                                booked_d.splice(yy, 1);
                              }
                            }
                          }

                          // Go through each new booked day and it to array
                          for (var jj = 0; jj < dateArray_new.length; jj ++ ) {
                            var _yyyy = dateArray_new[jj].getFullYear();
                            var _mm = dateArray_new[jj].getMonth() + 1;
                            var _dd = dateArray_new[jj].getDate();
                            if (_mm < 10){ _mm = "0" + _mm; }
                            if (_dd < 10){ _dd = "0" + _dd; }
                            dateArray_new[jj] = _yyyy + "-" + _mm + "-" + _dd;
                          }
                          // Add new dates
                          booked_d = booked_d.concat(dateArray_new);
                          gon.source[x].already_booked_dates = booked_d;
                          break;
                        }
                      }

                      // update datepicker
                      $('#start-on').val('');
                      $('#end-on').val('');
                      $('#datepicker').datepicker('remove');
                      updateDatepicker(booked_d);

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
              .error(function(data){
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
        }
      },
      onAddClick: function(dt, rowId) {
        //console.log(dt);
        //console.log(rowId);
      },
      onRender: function() {
        initializeThemes();
        $(".webui-popover").css("background-color","#714565");

        // Change leftPanel size depending on Rentog functionality
        if(gon.only_pool_tool){
          $(".leftPanel").width("224px");
          $(".fn-wide").width("220px");
        }

        initialize_listing_previews();

        // Stop spinner
        window.ST.pooToolSpinner.stop();

        // Show page content (pooltool, buttons, ...)
        $('#poolTool_Wrapper').animate({opacity: 1.0},1500);

        // Event listener for Rename Legend
        $('#showLegendId').on('click', function(){
          if ($('#showLegendId').html() === gon.show_legend){
            $('#showLegendId').html(gon.hide_legend);
          }else{
            $('#showLegendId').html(gon.show_legend);
          }
        });

        // Disable navigation buttons
        if($('.dataPanel').data('view') === 'days'){
          $('.nav-zoomIn').css('opacity', 0.4);
          $('.nav-zoomOut').css('opacity', 1);
        }
        if($('.dataPanel').data('view') === 'weeks'){
          $('.nav-zoomIn').css('opacity', 1);
          $('.nav-zoomOut').css('opacity', 1);
        }
        if($('.dataPanel').data('view') === 'months'){
          $('.nav-zoomIn').css('opacity', 1);
          $('.nav-zoomOut').css('opacity', 0.4);
        }


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

    var from8_ms = Math.round(new Date(new Date(today).setDate(today.getDate()-1)).getTime());
    var to8_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+15)).getTime());

    var from9_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+2)).getTime());
    var to9_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+4)).getTime());
    var from10_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+7)).getTime());
    var to10_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+19)).getTime());
    var from11_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+45)).getTime());
    var to11_ms = Math.round(new Date(new Date(today).setDate(today.getDate()+55)).getTime());

    return [
        {
          name: "Test Device 1",
          desc: "intern",
          dummy: "true",
          values: [{
            from: "/Date(" + from1_ms + ")/",
            to: "/Date(" + to1_ms + ")/",
            label: "Max Mustermann",
            customClass: "gantt_ownEmployee"
          }]
        },
        {
          name: "Test Device 2",
          desc: "trusted",
          dummy: "true",
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
              label: "Hermann Wagner",
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
          dummy: "true",
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
              label: "Geräte-Kalibrierung",
              customClass: "gantt_ownEmployee"
            },
            {
              from: "/Date(" + from7_ms + ")/",
              to: "/Date(" + to7_ms + ")/",
              label: "Renting Organization 1",
              customClass: "gantt_trustedCompany"
            }
          ]
        },
        {
          name: "Test Device 4",
          desc: "intern",
          dummy: "true",
          values: [
            {
              from: "/Date(" + from8_ms + ")/",
              to: "/Date(" + to8_ms + ")/",
              label: "Renting Organization 5",
              customClass: "gantt_trustedCompany"
            }
          ]
        },
        {
          name: "Test Device 5",
          desc: "trusted",
          dummy: "true",
          values: [
            {
              from: "/Date(" + from9_ms + ")/",
              to: "/Date(" + to9_ms + ")/",
              label: "Helga Hummel",
              customClass: "gantt_ownEmployee"
            },
            {
              from: "/Date(" + from10_ms + ")/",
              to: "/Date(" + to10_ms + ")/",
              label: "Interne Revision",
              customClass: "gantt_otherReason"
            },
            {
              from: "/Date(" + from11_ms + ")/",
              to: "/Date(" + to11_ms + ")/",
              label: "Hermann Wagner",
              customClass: "gantt_ownEmployee"
            }
          ]
        }
    ];
  };


  var calculateLoadFactor = function(entry){
     // Calculate load factor
    var created_at = new Date(entry.created_at);
    var today = new Date();
    today.setHours(0);
    today.setMinutes(0);
    today.setSeconds(0);
    created_at.setHours(0);
    created_at.setMinutes(0);
    created_at.setSeconds(0);

    // count booked (week)days till now
    var count_booked_weekdays = 0;
    var count_booked_days = 0;
    var oneDay = 24*60*60*1000;

    if (entry.values){
        for (var y=0; y<entry.values.length; y++){
            // Only calculate to booked dates if this booking is not another reason (like maintainance)
            if (entry.values[y].customClass !== "gantt_otherReason" &&
                entry.values[y].customClass !== "gantt_otherReason_me" &&
                entry.values[y].customClass !== "ganttHidden"){
                var _start = new Date(parseInt(entry.values[y].from.substr(6,13)));
                var _end   = new Date(parseInt(entry.values[y].to.substr(6,13)));
                _start.setHours(0);
                _end.setHours(0);
                _start.setMinutes(0);
                _end.setMinutes(0);
                _start.setSeconds(0);
                _end.setSeconds(0);

                if (_start > today){
                    continue;
                }

                // Check if booking start is before created_at date, if yes
                // then change the created_at date of the listing, because then
                // the start point for the device should be the day of the first
                // booking
                if (_start < created_at){
                    created_at = new Date(_start);
                }

                // Only get booked day which are not on weekend
                var _booked_days = getDatesBetweenRange(_start, _end);
                for (var yy=0; yy<_booked_days.length; yy++){
                    // Check if current day is bigger than today
                    if(_booked_days[yy] <= today){
                      count_booked_days++;

                      if (_booked_days[yy].getDay() !== 6 && _booked_days[yy].getDay() !== 0){
                          count_booked_weekdays++;
                      }
                    }
                }
            }
        }
    }

    // count (week)days till now
    var count_weekdays = 0;
    var count_days = 0;
    var  x = new Date(created_at);

    while (x<=today){
        count_days++;
        // increase weekdays if not sunday or saturday
        if (x.getDay() !== 6 && x.getDay() !== 0){
            count_weekdays++;
        }
        x.setDate(x.getDate() + 1);
    }


    // Calculate percentage
    var weekday_load = 0;
    var day_load = 0;
    var load_class = "load_red";
    if (entry.name){
        // if just dummy listing
        if(entry.dummy !== undefined){
            if (entry.name === 'Test Device 5'){
                weekday_load = 90.0;
                day_load = 85.0;
            }else if (entry.name === 'Test Device 4'){
                weekday_load = 61.0;
                day_load = 58.0;
            }
            else if (entry.name === 'Test Device 3'){
                weekday_load = 85.0;
                day_load = 83.0;
            }else if (entry.name === 'Test Device 2'){
                weekday_load = 35.0;
                day_load = 32.0;
            }else{
                weekday_load = 22.0;
                day_load = 20.0;
            }
        }else{
            // Calculate load factor
            if (count_weekdays > 0){
                weekday_load = count_booked_weekdays / count_weekdays * 100;
            }
            if (count_days > 0){
                day_load = count_booked_days / count_days * 100;
            }

            weekday_load = (Math.round(weekday_load * 100) / 100).toFixed(1);
            day_load = (Math.round(day_load * 100) / 100).toFixed(1);
        }

        if (weekday_load > 70){
            load_class = "load_green";
        }else if (weekday_load > 40 ){
            load_class = "load_yellow";
        }
    }

    return {
        load_class: load_class,
        count_weekdays: count_weekdays,
        count_days: count_days,
        count_booked_days: count_booked_days,
        count_booked_weekdays: count_booked_weekdays,
        weekday_load: weekday_load,
        day_load: day_load,
        utilization_start: created_at
    };
  };

  return {
    init: init,
    updateGanttChart: updateGanttChart,
    calculateLoadFactor: calculateLoadFactor
  };
};
