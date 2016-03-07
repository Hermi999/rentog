/* Tell jshint that there exists a global called gon */
/* globals gon, prettyPrint, initialize_poolTool_createTransaction_form, getDatesBetweenRange, getDaysBetweenDates, Spinner, console */
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
  color: '#1f90a4',      // #rgb or #rrggbb or array of colors
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
  position: 'absolute'   // Element positioning
};
window.ST.pooToolSpinner = new Spinner(opts).spin();



window.ST.poolTool = (function() {
  var searchTimeout, searchTermOld = "";

  console.log("===== Pool Tool Code called =====");

  // Initialize the whole pool tool (jquery gantt chart, date pickers, add new booking form, ...)
  function init(){
    $('.page-content').append(window.ST.pooToolSpinner.el);
    changeDesign();
    initializeCheckOrientation();
    initializeGantt();
    initializeDatepickers();
    initialize_poolTool_createTransaction_form(gon.locale, gon.choose_employee_or_renter_msg);
    initialize_device_picker();
    initialize_poolTool_options();
    initialize_poolTool_search();

    // Show devices the current logged in user has in his hands
    if (gon.user_active_bookings !== null){
      show_my_borrowed_devices();
    }

    $(".inline").colorbox({inline:true, width:"90%", height:"95%", maxWidth:"500px", maxHeight:"270px"});
  }

  // Removes all borrowed booking cards (divs) and then calls the method for showing the borrowed devices
  // This is used for updating the view, for example after a booking has been deleted, changed or created
  function update_my_borrowed_devices(){
    if (gon.user_active_bookings !== null){
      $('.user_booking').remove();
      $('.no-open-bookings').remove();
      show_my_borrowed_devices();
    }
  }

  // Show devices the current logged in user has in his hands at this moment
  function show_my_borrowed_devices(){
    // gon.user_active_bookings = only bookings which are booked by the user AND
    // are currently in state active (that means the user hadn't give them back) AND
    // are past

    if (gon.pool_tool_preferences.pooltool_user_has_to_give_back_device !== true){
      return false;
    }

    // Update the array with the original bookings from the db, if the user
    // changed the bookings with the gantt chart
    update_bookings_after_gantt_chart_update();

    // Deep copy the user_active_bookings into a new object
    var _user_active_bookings = $.extend(true, [], gon.user_active_bookings);

    // Remove all bookings which are neither active nor open and store them in
    // an new array
    _user_active_bookings = remove_future_bookings(_user_active_bookings);

    // If two bookings belong to the same listing, remove the older one
    _user_active_bookings = remove_old_bookings(_user_active_bookings);

    // No open bookings - only show a message
    if (_user_active_bookings.length === 0){
      $('#my_devices')
        .append($('<div class="no-open-bookings" />')
          .html(gon.no_devices_borrowed));
    }
    // Otherwise remove message and show the device cards
    else{
      $('.no-open-bookings').remove();

      for(var i=0; i<_user_active_bookings.length; i++){
        var title = _user_active_bookings[i].title;
        var desc = _user_active_bookings[i].description;
        var start_on = _user_active_bookings[i].start_on;
        var start_on_date = new Date(start_on);
        var end_on = _user_active_bookings[i].end_on;
        var end_on_date = new Date(end_on);
        var listing_id = _user_active_bookings[i].listing_id;
        var transaction_id = _user_active_bookings[i].transaction_id;
        var image = "";
        var today = new Date(new Date().setHours(1,0,0,0));
        var overdue = 0;

        if (today > end_on_date){
          overdue = getDaysBetweenDates(today, end_on_date);
        }

        for (var ii=0; ii<gon.source.length; ii++){
          if (listing_id === gon.source[ii].listing_id){
            image = gon.source[ii].image;
            break;
          }
        }

        // Create the device cards by adding element to the DOM with jquery
        $('#my_devices')
          .append($('<div class="col-4 user_booking" id="open_booking_'+ transaction_id +'" />')
            .append($('<div class="user_booking_data"/>')
              .append($('<p class="user_booking_header">')
                .append($('<span class="user_booking_header_title">')
                  .html(title))
                .append($('<p class="user_booking_overdue" id="overdue_'+ i +'">')
                  .html(gon.overdue + overdue + " days")))
              .append('<img src="' + image + '" class="user_booking_img" />')
              .append($('<span class="return_on" />')
                .html(gon.return_on))
              .append(end_on)
            )
            .append($('<button id="return_now_' + i + '" />')
              .html(gon.return_now)
            )
          );

        // Remove overdue element if it's < 1 days
        if(overdue < 1){
          $('#overdue_' + i).remove();
        }

        // Store transaction_id with the 'return now' button
        $('#return_now_' + i).data('transaction_id', transaction_id);


        // On click on button
        // ATTENTION: Function in a loop. Do not use a reference from the outside
        // within that loop
        /*jshint -W083 */
        $('#return_now_'+ i).on('click', function(ev){
          transaction_id = $('#' + ev.currentTarget.id).data('transaction_id');

          // Update database on server
          $.ajax({
            type: "PUT",
            url: '/update_device_returned',
            data: {transaction_id: transaction_id, device_returned: true},
          })
            .done(function(data){
              // Update the original gon.user_active_bookings Array
              for (var x=0; x<gon.user_active_bookings.length; x++){
                if (gon.user_active_bookings[x].transaction_id === transaction_id){
                  gon.user_active_bookings.splice(x, 1);
                  break;
                }
              }

              // Update the bookings copy _user_active_bookings Array
              for (x=0; x<_user_active_bookings.length; x++){
                if (_user_active_bookings[x].transaction_id === transaction_id){
                  _user_active_bookings.splice(x, 1);
                  break;
                }
              }

              update_my_borrowed_devices();

              if (end_on_date > today){
                var e_new = today;
                // Update the gantt chart (with the new source)
                updateGanttDatepickerBorrowedDevices(transaction_id, listing_id, start_on_date, e_new, start_on_date, end_on_date, title, desc, false);
              }

            })
            .fail(function(){

            });
        });
      }
    }
  }

  // Update the active bookings array with the values from the db.
  function update_bookings_after_gantt_chart_update(){
    if (gon.user_active_bookings !== null){
      for(var i=0; i<gon.user_active_bookings.length; i++){
        for(var j=i+1; j<gon.user_active_bookings.length; j++){
          if (gon.user_active_bookings[i].listing_id === gon.user_active_bookings[j].listing_id){

            // If transaction id is the same, then the booking was updated via the gantt chart
            if (gon.user_active_bookings[i].transaction_id === gon.user_active_bookings[j].transaction_id){
              if (gon.user_active_bookings[i].update === true){
                // Take over attributes from gantt change & remove the object created
                // with the gantt change
                gon.user_active_bookings[j].end_on = gon.user_active_bookings[i].end_on;
                gon.user_active_bookings[j].start_on = gon.user_active_bookings[i].start_on;
                gon.user_active_bookings[j].description = gon.user_active_bookings[i].description;
                gon.user_active_bookings.splice(i, 1);
              }else{
                // Take over attributes from gantt change & remove the object created
                // with the gantt change
                gon.user_active_bookings[i].end_on = gon.user_active_bookings[j].end_on;
                gon.user_active_bookings[i].start_on = gon.user_active_bookings[j].start_on;
                gon.user_active_bookings[i].description = gon.user_active_bookings[j].description;
                gon.user_active_bookings.splice(j, 1);
              }
            }
          }
        }
      }

      // Set 'update' to false if there is a booking left which is an update.
      // This only happens if there was no booking there of this listing before
      for(var k=0; k<gon.user_active_bookings.length; k++){
        if (gon.user_active_bookings[k].update === true){
          gon.user_active_bookings[k].update = false;
        }
      }
    }
  }

  // If two open bookings of the user belong to the same listing, remove the older one
  // This function is used for showing the current borrowed devices
  function remove_old_bookings(bookings){
    for(var i=0; i<bookings.length; i++){
      for(var j=i+1; j<bookings.length; j++){
        if (bookings[i].listing_id === bookings[j].listing_id){
          // Remove the booking, which has the earlier return date
          if (new Date(bookings[i].end_on) < new Date(bookings[j].end_on)){
            bookings.splice(i, 1);
            j--;
          }else{
            bookings.splice(j, 1);
            j--;
          }
        }
      }
    }

    return bookings;
  }

  // Check if start date is greater than today and remove booking if thats
  // the case. This can happen if a booking is updated via the gantt chart
  function remove_future_bookings(bookings){
    var today = new Date(new Date().setHours(1,0,0,0));

    for(var i=0; i<bookings.length; i++){
      if(new Date(bookings[i].start_on) > today){
        bookings.splice(i, 1);
        i--;
      }
    }

    return bookings;
  }


  // Only show bookings in the gantt chart who belong to the user
  function show_only_mine(){
    if($('.only_mine').prop('checked')){
      $('.bar').hide();
      $('.gantt_trustedEmployee_me').show();
      $('.gantt_ownEmployee_me').show();
      $('.gantt_anyCompany_me').show();
      $('.gantt_trustedCompany_me').show();
      $('.gantt_otherReason_me').show();
    }else{
      $('.bar').show();
    }
  }


  // Initialize the pool tool options, like "Show only mine", ...
  function initialize_poolTool_options(){
    // Show only my bookings (the current user)
    $('.only_mine').prop('checked', false);

    $('.only_mine').on('change', function(){
      show_only_mine();
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
        $(this).val($(this).val().substring(0, desc_maxchars));
        var tlength = $(this).val().length;
        var remain = desc_maxchars - parseInt(tlength);
        $('#description_counter').html(remain);
    });

    // Do not allow more than 40 chars for the reason
    var reason_maxchars = 40;
    $('#tf_device_renter').keyup(function () {
        var tlength = $(this).val().length;
        var remain = reason_maxchars - parseInt(tlength);
        $('#reason_counter').html(remain);
    });
  }

  // Initialize the listings picture preview. The listings picture should be
  // shown if the user hovers a listing in the gantt chart
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

  // Within the pool tool we need a wider screen. This functions adds the
  // necessary classes to the wrapper-divs
  function changeDesign(){
    // FULLSCREEN
    $('.header-wrapper').addClass('fullscreen');
    $('.title-header-wrapper').addClass('fullscreen');
    $('.page-content .wrapper').addClass('fullscreen');

    // Change background-color if on another companies pool tool
    if (!gon.belongs_to_company){
      var color_background = "rgb(243, 196, 188)";
      var color_title_container = "rgb(231, 78, 53)";

      $('body').css('background-color', color_background);
      $('.page-content').css('background-color', color_background);
      $('.wrapper').css('background-color', color_background);
      $('.title-container').css('background-color', color_title_container);
      $('.marketplace-title-header>h1').css("color", "white");
    }
  }


  // Initialize the different themes and the checkbox callbacks & set the default theme
  function initializeThemes(){
    var allThemes  = ["theme_dark", "theme_red", "theme_white"];
    var allClasses = ["gantt", "header_g", "row_g", "wd_g", "sa_g", "sn_g",
                      "today", "navigate", "fn-content", "legend", "dataPanel_past",
                      "gantt_otherReason", "ganttLegend_otherReason", "gantt_otherReason_me",
                      "gantt_ownEmployee", "ganttLegend_ownEmployee", "gantt_ownEmployee_me",
                      "gantt_trustedEmployee", "ganttLegend_trustedEmployee", "gantt_trustedEmployee_me",
                      "gantt_anyCompany", "ganttLegend_anyCompany", "gantt_anyCompany_me",
                      "gantt_trustedCompany", "ganttLegend_trustedCompany","gantt_trustedCompany_me",
                      "gantt_privateBooking", "ganttLegend_privateBooking","gantt_privateBooking_me",
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

  // Actually changes the theme by removing and adding classes to the DOM objects
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

  // Saves which themes the users has selected into the database
  function saveTheme(theme){
    $.ajax({
      method: "post",
      dataType: "json",
      url: "/" + gon.current_user_username + "/poolToolTheme",
      data: {theme: theme},
    })
    .success(function(data){
      // Do not show any message to user
    })
    .error(function(data){
      // Do not show any message to user
    });
  }

  // Saves if legend is shown by user or not
  function saveLegend(legend){
    $.ajax({
      method: "post",
      dataType: "json",
      url: "/" + gon.current_user_username + "/poolToolLegend",
      data: {legend: legend},
    })
    .success(function(data){
      // Do not show any message to user
    })
    .error(function(data){
      // Do not show any message to user
    });
  }

  // Initialize the Datepickers (add new booking & edit existing booking).
  // Also add an eventlistener for updating the datepicker if the user changes
  // the listing in the 'add new booking form'
  function initializeDatepickers(){
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

    // If modifying the past is not allowed, then ensure this in the datepicker
    var start_date;
    if (!gon.pool_tool_preferences.pool_tool_modify_past){
      start_date = new Date(new Date().setHours(0,0,0,0));
    }

    window.ST.initializeFromToDatePicker('#datepicker', booked_dates, '#start-on', '#end-on', "#booking-start-output", "#booking-end-output", start_date);
    window.ST.initializeFromToDatePicker('#datepicker2', booked_dates, '#start-on2', '#end-on2', "#booking-start-output2", "#booking-end-output2");   // don't use start today, because the datepicker will remove the old dates


    // EVENT LISTENER: If the user changes the listing selected listing in the
    // "add new booking" form, then also update the booked dates in the datepicker
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

  // Initializes the first Datebicker with the 'booked_dates' array
  function updateDatepicker(booked_dates){
    // If modifying the past is not allowed, then ensure this in the datepicker
    var start_date;
    if (!gon.pool_tool_preferences.pool_tool_modify_past){
      start_date = new Date(new Date().setHours(0,0,0,0));
    }

    window.ST.initializeFromToDatePicker('#datepicker', booked_dates, '#start-on', '#end-on', "#booking-start-output", "#booking-end-output", start_date);
    $('#datepicker').datepicker('update');
  }

  // Initializes the second Datebicker with the 'booked_dates' array
  function updateDatepicker2(booked_dates, start_date){
    window.ST.initializeFromToDatePicker('#datepicker2', booked_dates, '#start-on2', '#end-on2', "#booking-start-output2", "#booking-end-output2", start_date);
    $('#datepicker2').datepicker('update');
  }


  // Initializes the jquery gantt plugin with the listings and their transactions.
  // Since gon.devices only hold the devices with transactions & gon.open_listings
  // only hold all open listings, but no transactions, those two arrays are merged and
  // then taken as source for initializing the gantt chart.
  function initializeGantt(){

    var source = jQuery.extend(true, [], gon.devices);  // deep copy - we don't change the gon.devices array
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
        // If listing is already within the source array, then there are
        // transactions. In this case only copy the image url
        if (gon.open_listings[j].name === source[k].name){
          already_there = true;

          // copy image url
          source[k].image = gon.open_listings[j].image;
        }
      }

      // If not already there store the listing without transactions in empty_arr
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

    // Attach listings without transactions to source array
    // Attach them after the internal, trusted, all listings, but before the external listings
    var temp_arr = [];

    if (source.length > 0){  // if there are already transactions
      for (var xx=0; xx<source.length; xx++){
        // copy reference to all intern, trusted, all listings
        if (source[xx].desc !== "extern"){
          temp_arr[xx] = source[xx];
        }
        else{
          // copy all references to listings without transactions
          temp_arr = temp_arr.concat(empty_arr);

          // copy all references to extern listings
          for (var ww=xx; ww<source.length; ww++){
            temp_arr[ww+empty_arr.length] = source[ww];
          }
          break;
        }
      }
      source = temp_arr;
    }
    // no transactions yet, but maybe already listings
    else{
      source = empty_arr;
    }

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

    // Gon.source points to source, so that we can access the source when adding an element to one device
    gon.source = source;

    // update gantt chart (with the new gon.source)
    updateGanttChart();

    prettyPrint();
  }


  // Handler for search field
  // Doesn't start the search immetiately, but with a slight delay, so that
  // the user can finish his word
  function initialize_poolTool_search(){
    $('#poolTool_search').keyup(function(){
      var value = $('#poolTool_search').val();

      clearTimeout(searchTimeout);

      searchTimeout = setTimeout(function(){
        search(value);
      }, 700);
    });

    // remove search text
    $('#remove_search').click(function(){
      $('#poolTool_search').val("");
      search("");
    });
  }

  // Search for the given term within the source of jquery GanttChart &
  // updates the ganttchart
  function search(term){
    var source = jQuery.extend(true, [], gon.source);  // deep copy - we don't change the gon.source array

    if (term.length < 3){
      term = "";
      if (searchTermOld !== term){
        searchTermOld = term;
        $('#poolTool_search').css("background-color", "white");
        $('#poolTool_search').css("color", "black");
        updateGanttChart(source);
      }
    }

    if (searchTermOld !== term){
      searchTermOld = term;

      if (term.length > 2){
        for (var x = 0; x < source.length; x++){
          var re = new RegExp(term, "i");
          var remove1 = false;
          var remove2 = false;

          // device name
          if (source[x].name){
            var result_name = source[x].name.match(re);

            if (result_name === null){
              remove1 = true;
            }
          }

          // device availability
          if (source[x].desc){
            var locale_desc = gon["availability_desc_header_" + source[x].desc];
            var result_avail = locale_desc.match(re);

            if (result_avail === null){
              remove2 = true;
            }
          }

          if (remove1 && remove2){
            source.splice(x, 1);
            x = x-1;
          }
        }
        if (source.length < 2){
          // red
          $('#poolTool_search').css("background-color", "rgb(241, 188, 188)");
          $('#poolTool_search').css("color", "rgb(130,30,30)");
        }else{
          // green
          $('#poolTool_search').css("background-color", "rgb(189, 241, 202)");
          $('#poolTool_search').css("color", "green");
        }

        updateGanttChart(source);
      }
    }
  }


  // This function actually initializes and updates the jquery gantt chart. It
  // also defines the actions for the event listeners "onItemClick", "onAddClick" and
  // "onRender".
  // The "onItemClick" Event-Handler handles the whole functionality of the update
  // dialog.
  // The "onRender" Event-Handler handles all the stuff which can only be done
  // after the jquery gantt plugin has been rendered, like stopping the spinner,
  // adding event listeners for the legend, disable jquery gantt navigation buttons, ...
  function updateGanttChart(source){
    source = source || gon.source;

    var count_extern = 0;
    for (var oo = 0; oo < source.length; oo++){
      if (source[oo].desc === "extern"){
        count_extern ++;
      }
    }
    gon.count_extern_listings = count_extern;

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
        var title = info.listing.name;
        var today = new Date(new Date().setHours(0,0,0,0));

        // Update shown information in popover
        if (typeof info.listing.image !== "undefined") {
          $('#poolTool_popover_deviceImage').attr('src', info.listing.image);
        }else{
          $('#poolTool_popover_deviceImage').attr('src', "/assets/logos/mobile/default.png");
        }
        $('#poolTool_popover_deviceName').html(info.listing.name);
        $('#poolTool_popover_renter').html(info.booking.label);
        $('#poolTool_popover_availability').html(info.listing.availability);
        $('#ta_popover_description').val(info.booking.description);

        // Open Popover
        $('#modifyBookingLink').click();

        // Remove buttons and disable textfields if
        // - user is not a company admin or rentog admin AND
        // - this is not a booking of the user AND
        // - the current user is not the company admin of the transaction starter OR
        // - it's not allowed to change the past and the booking is already in the past
        if ((gon.is_admin === false && info.booking.renter_id !== gon.current_user_id && gon.current_user_id !== info.booking.renter_company_id) ||
            (info.booking.customClass === "gantt_privateBooking") ||
            (!gon.pool_tool_preferences.pool_tool_modify_past && e < today)){
          $('#btn_update').css('display', 'none');
          $('#btn_delete').css('display', 'none');

          // initialize the datepicker with the booked_dates array
          $('#start-on2').val('');
          $('#end-on2').val('');
          $('#datepicker2').datepicker('remove');
          updateDatepicker2([]);

          // Set dates with datepicker, because then we have the correct
          // format for the current language
          $('#end-on2').datepicker('setDate', e);
          $('#start-on2').datepicker('setDate', s);

          // Disable datepickers
          $('#start-on2').prop('disabled', true);
          $('#end-on2').prop('disabled', true);
          $('#ta_popover_description').prop('disabled', true);
        }

        // If user is company admin or owner of the booking
        // Re-initialize Datepickers with booked dates
        else{
          var start_is_in_past = false;

          // Activate all the buttons and textfields
          $('#btn_update').css('display', 'inline');
          $('#btn_delete').css('display', 'inline');
          $('#start-on2').prop('disabled', false);
          $('#end-on2').prop('disabled', false);
          $('#ta_popover_description').prop('disabled', false);

          // If modifying the past is not allowed, then ensure this in the datepicker
          if (!gon.pool_tool_preferences.pool_tool_modify_past){
            // Disable start-on2 datepicker if start-on is in the past
            if (s < today){
              $('#start-on2').prop('disabled', true);
              $('#btn_delete').css('display', 'none');
              start_is_in_past = true;
            }
          }

          // Initialize the two datepickers
            // Get all the booked dates of the listing this booking is for by
            // copying the array into 'booked_dates', because we do not want to
            // get our source changed
            for(var y=0; y<gon.source.length; y++){
              if(gon.source[y].listing_id === listing_id){
                if (gon.source[y].already_booked_dates){
                  booked_dates = gon.source[y].already_booked_dates.slice();
                }
                break;
              }
            }

            // Remove the days from this current booking from the booked_dates array
            // The user can choose those days again
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

            // initialize the datepicker with the booked_dates array
            $('#start-on2').val('');
            $('#end-on2').val('');
            $('#datepicker2').datepicker('remove');

            // If modifying the past is not allowed, then ensure this in the datepicker
            if (!gon.pool_tool_preferences.pool_tool_modify_past){
              if (start_is_in_past){
                updateDatepicker2(booked_dates, s);
              }else{
                var start_date = new Date(new Date().setHours(0,0,0,0));
                updateDatepicker2(booked_dates, start_date);
              }
            }else{
              updateDatepicker2(booked_dates);
            }

            // Set datepicker dates to those from db
            $('#start-on2').datepicker('setDate', s);
            $('#end-on2').datepicker('setDate', e);


          // Remove old event listeners from the buttons
          $('#btn_update').unbind();
          $('#btn_delete').unbind();


          // EVENT LISTENER: Remove booking in gantt chart and db
          $('#btn_delete').on('vclick', function(){
            // User has to confirm the deletion first
            var result = window.confirm(gon.deleteConfirmation);

            if (result){
              // Add event listeners for remove booking from db
              $.ajax({
                method: "post",   // Browser can't do delete requests
                dataType: "json",
                url: "/" + gon.locale + "/" + gon.pooltool_owner_id + "/transactions/" + transaction_id,
                data: {_method:'delete'},
                beforeSend :function(){
                  // Disable Sumbmit Buttons until we get an response from the server
                  // In this way the the user cannot click twice on the button and
                  // create multiple updates to the server
                  $("#btn_update").prop('disabled', true);
                  $("#btn_delete").prop('disabled', true);
                  $('#btn_update').css('opacity', 0.6);
                  $('#btn_delete').css('opacity', 0.6);
                }
              })
                .success(function(ev){
                  // If the server code was also successful
                  if (ev.status === "success"){

                    // Remove visual element from gantt chart
                    data.remove();

                    // Update source for gantt chart
                    var booked_d = [];
                    for(var x=0; x<gon.source.length; x++){
                      if(gon.source[x].listing_id === listing_id){
                        for(var y=0; y<gon.source[x].values.length; y++){
                          if(gon.source[x].values[y].transaction_id === transaction_id){
                            // Remove element from array
                            gon.source[x].values.splice(y, 1);

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
                              booked_d = gon.source[x].already_booked_dates;

                              // Compare and remove
                              for (var yy =0; yy < booked_d.length; yy++){
                                if (booked_d[yy] === new_date){
                                  booked_d.splice(yy, 1);
                                }
                              }
                            }

                            // Terminate the loops
                            x = gon.source.length;
                            break;
                          }
                        }
                      }
                    }

                    // update the datepickers
                    $('#start-on').val('');
                    $('#end-on').val('');
                    $('#datepicker').datepicker('remove');
                    updateDatepicker(booked_d);

                    // Update the gantt chart (with the new source)
                    updateGanttChart();

                    // Update the 'borrowed devices' by also removing the current
                    // booking from the active bookings array and calling the
                    // borrowed_devices function
                    for (var aa=0; aa<gon.user_active_bookings.length; aa++){
                      if (gon.user_active_bookings[aa].transaction_id === transaction_id){
                        gon.user_active_bookings.splice(aa, 1);
                        break;
                      }
                    }
                    update_my_borrowed_devices();
                  }

                  // Close popover
                  $.colorbox.close();

                  // Enable Submit button again (wait a little, so that popover is closed)
                  setTimeout(function(){
                    $("#btn_update").prop('disabled', false);
                    $("#btn_delete").prop('disabled', false);
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
                  $("#btn_delete").prop('disabled', false);
                  $('#btn_update').css('opacity', 1);
                  $('#btn_delete').css('opacity', 1);
                });
            }
          });


          // EVENT LISTENER: Ubdate booking in gantt chart and db
          $('#btn_update').on('vclick', function(){
            var s_new = new Date($('#booking-start-output2').val());
            var e_new = new Date($('#booking-end-output2').val());
            var desc = $('#ta_popover_description').val();

            $.ajax({
              method: "PUT",
              url: "/" + gon.locale + "/" + gon.pooltool_owner_id + "/transactions/" + transaction_id,
              data: {from: s_new, to: e_new, desc: desc},
              beforeSend: function(){
                // Disable Sumbmit Buttons until we get an response from the server
                // In this way the the user cannot click twice on the button and
                // create multiple updates to the server
                $("#btn_update").prop('disabled', true);
                $("#btn_delete").prop('disabled', true);
                $('#btn_update').css('opacity', 0.6);
                $('#btn_delete').css('opacity', 0.6);
              }
            })
              .success(function(data){
                if (data.status === "success"){
                  // update gantt view & source
                  // Update datepicker
                  updateGanttDatepickerBorrowedDevices(transaction_id, listing_id, s_new, e_new, s, e, title, desc, true);

                }
                else{
                  // Show error message and fade it out after some time
                  var msg = $('#error_message').html();
                  var received_msg = data.message || msg;
                  $('#error_message').html(received_msg);
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
                  $("#btn_delete").prop('disabled', false);
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
                $("#btn_delete").prop('disabled', false);
                $('#btn_update').css('opacity', 1);
                $('#btn_delete').css('opacity', 1);
              });
          });
        }
      },
      onAddClick: function(dt, rowId) {
        console.log(dt);
        console.log(rowId);
      },
      onRender: function() {
        initializeThemes();
        $(".webui-popover").css("background-color","#714565");

        // Change leftPanel size depending on Rentog functionality
        if (!gon.belongs_to_company){    //(gon.only_pool_tool){
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
            saveLegend(true);
          }else{
            $('#showLegendId').html(gon.show_legend);
            saveLegend(false);
          }
        });

        // Set legend according to db stored status
        if (gon.legend_status === "1"){
          $('.legend').show();
          $('#showLegendId').html(gon.hide_legend);
        }else{
          $('.legend').hide();
          $('#showLegendId').html(gon.show_legend);
        }

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

        // update gantt chart bookings depending on the 'Show only mine' checkbox
        show_only_mine();

      }
    });
  }

  function updateGanttDatepickerBorrowedDevices(transaction_id, listing_id, s_new, e_new, s, e, title, desc, showinborroweddevices){
    var booked_d;
    for(var x=0; x<gon.source.length; x++){
      if(gon.source[x].listing_id === listing_id){

        // Update start and end date & description
        for(var y=0; y<gon.source[x].values.length; y++){
          if(gon.source[x].values[y].transaction_id === transaction_id){
            gon.source[x].values[y].from = "/Date(" + Math.round(s_new.getTime()) + ")/";
            gon.source[x].values[y].to = "/Date(" + Math.round(e_new.getTime()) + ")/";
            gon.source[x].values[y].description = desc;
            break;
          }
        }

        // New reference
        booked_d = gon.source[x].already_booked_dates;

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

    // Update gantt chart
    updateGanttChart();

    if (showinborroweddevices){
      // Update the 'borrowed devices' by adding the changed
      // transaction as new booking. This change booking is
      // marked as update, so that the changes can be taken over and this entry
      // can be deleted in the update_borrowed_device() function
      var now = new Date(new Date().setHours(1,0,0,0));
      gon.user_active_bookings.push({
        update: true,
        transaction_id: transaction_id,
        listing_id: listing_id,
        start_on: s_new.getFullYear() + "-" + (s_new.getMonth()+1) + "-" + s_new.getDate(),
        end_on: e_new.getFullYear() + "-" + (e_new.getMonth()+1) + "-" + e_new.getDate(),
        title: title
      });
    }else{
      // Update the 'borrowed devices' by removing the current
      // booking from the active bookings array
      for (var aa=0; aa<gon.user_active_bookings.length; aa++){
        if (gon.user_active_bookings[aa].transaction_id === transaction_id){
          gon.user_active_bookings.splice(aa, 1);
          break;
        }
      }
    }

    update_my_borrowed_devices();
  }


  // Initializes the radio button listing device picker by defining an onclick
  // event handler
  function initialize_device_picker(){
    $('.pooltool_grid_item_modifier_class').on('vclick', function(ev){
      ev.preventDefault();
      if(ev.currentTarget.nextElementSibling && ev.currentTarget.nextElementSibling.className === "radiobutton_griditem"){
        ev.currentTarget.nextElementSibling.firstElementChild.checked = true;
        $('#' + ev.currentTarget.nextElementSibling.firstElementChild.id).change();
      }
    });
  }

  // Calls check orientation function and adds eventlistener to window for
  // orientationchange event.
  function initializeCheckOrientation(){
    window.addEventListener("orientationchange", function() {
        setTimeout(function(){
          check_orientation();
        }, 150);
    });
    check_orientation();
  }

  // Show "change orientation" on small devices, like smartphones
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

  // Create dummy listings for the gantt chart
  // This is used when there are not listing yet
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

  // Calculates the load factor of all entries given as parameter
  // This is used be the jquery gantt plugin code to show the load factor
  var calculateLoadFactor = function(entry){
     // Calculate load factor
    var created_at = new Date(entry.created_at);
    var today = new Date(new Date().setHours(0,0,0,0));
    created_at.setHours(0);
    created_at.setMinutes(0);
    created_at.setSeconds(0);

    // count booked (week)days till now
    var count_booked_weekdays = 0;
    var count_booked_days = 0;

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

  // Return functions which should be callable from the outside
  return {
    init: init,
    updateGanttChart: updateGanttChart,
    calculateLoadFactor: calculateLoadFactor,
    update_my_borrowed_devices: update_my_borrowed_devices
  };
})();
