/* Tell jshint that there exists a global called "gon" */
/* globals gon */
/* jshint unused: false */

window.ST = window.ST || {};


window.ST.poolTool = function() {
  var clickDate = "";
  var clickAgendaItem = "";
  var jfcalplugin = {};
  var temp_dates = {"booking-start-output": "", "booking-end-output": ""};

  function init(){
    initializeFromToDatePicker('add-event-form');
    initialize_poolTool();
    add_listings_to_calender();
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




  var source = [{
        name: "Sprint 0",
        desc: "Analysis",
        values: [{
          from: "/Date(1320192000000)/",
          to: "/Date(1322401600000)/",
          label: "Requirement Gathering",
          customClass: "ganttRed"
        }]
      },{
        name: " ",
        desc: "Scoping",
        values: [{
          from: "/Date(1322611200000)/",
          to: "/Date(1323302400000)/",
          label: "Scoping",
          customClass: "ganttRed"
        }]
      },{
        name: "Sprint 1",
        desc: "Development",
        values: [{
          from: "/Date(1323802400000)/",
          to: "/Date(1325685200000)/",
          label: "Development",
          customClass: "ganttGreen"
        }]
      },{
        name: " ",
        desc: "Showcasing",
        values: [{
          from: "/Date(1325685200000)/",
          to: "/Date(1325695200000)/",
          label: "Showcasing",
          customClass: "ganttBlue"
        }]
      },{
        name: "Sprint 2",
        desc: "Development",
        values: [{
          from: "/Date(1326785200000)/",
          to: "/Date(1325785200000)/",
          label: "Development",
          customClass: "ganttGreen"
        }]
      },{
        name: " ",
        desc: "Showcasing",
        values: [{
          from: "/Date(1328785200000)/",
          to: "/Date(1328905200000)/",
          label: "Showcasing",
          customClass: "ganttBlue"
        }]
      },{
        name: "Release Stage",
        desc: "Training",
        values: [{
          from: "/Date(1330011200000)/",
          to: "/Date(1336611200000)/",
          label: "Training",
          customClass: "ganttOrange"
        }]
      },{
        name: " ",
        desc: "Deployment",
        values: [{
          from: "/Date(1336611200000)/",
          to: "/Date(1338711200000)/",
          label: "Deployment",
          customClass: "ganttOrange"
        }]
      },{
        name: " ",
        desc: "Warranty Period",
        values: [{
          from: "/Date(1336611200000)/",
          to: "/Date(1349711200000)/",
          label: "Warranty Period",
          customClass: "ganttOrange"
        }]
      }];



  function initializeGantt(){
    $(".gantt").gantt({
      navigate: "scroll",
      minScale: "days",
      itemsPerPage: 10,
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
        /*if (window.console && typeof console.log === "function") {
          console.log("chart rendered");
        }*/
      }
    });

    prettyPrint();
    $( "#draggme" ).draggable();
  }







  $("#shownMonth").html(gon.translated_months[new Date().getMonth('MM')] + " " + new Date().getFullYear());

  /**
   * Initialize our tabs
   * Our calendar is initialized in a closed tab so we need to resize it when the example tab opens.
   */
  $("#tabs").tabs({
    show: function(event, ui){
      if(ui.index === 1){
        jfcalplugin.doResize("#mycal");
      }
    }
  });

  function initializeFromToDatePicker(rangeCongainerId) {
    var dateRage = $('#'+ rangeCongainerId);
    var options = {
      inputs: [$("#startDate"), $("#endDate")],
    };

    if(gon.locale !== 'en') {
      options.language = gon.locale;
    }

    var picker = dateRage.datepicker(options);

    var outputElements = {
      "booking-start-output": $("#booking-start-output"),
      "booking-end-output": $("#booking-end-output")
    };

    picker.on('changeDate', function(e) {
      var newDate = e.dates[0];
      var outputElementId = $(e.target).data("output");
      var outputElement = outputElements[outputElementId];
      var temp_date = ST.utils.toISODate(newDate);
      outputElement.val(temp_date);
      temp_dates[outputElementId] = temp_date;
    });
  }

  /**
   * Initializes calendar with current year & month
   * specifies the callbacks for day click & agenda item click events
   * then returns instance of plugin object
   */
  function initialize_poolTool (){
    jfcalplugin = $("#mycal").jFrontierCal({
      date: new Date(),
      dayClickCallback: myDayClickHandler,
      agendaClickCallback: myAgendaClickHandler,
      agendaDropCallback: myAgendaDropHandler,
      agendaMouseoverCallback: myAgendaMouseoverHandler,
      applyAgendaTooltipCallback: myApplyTooltip,
      agendaDragStartCallback : myAgendaDragStart,
      agendaDragStopCallback : myAgendaDragStop,
      dragAndDropEnabled: true
    }).data("plugin");

    /**
     * Make the day cells roughly 3/4th as tall as they are wide. this makes our calendar wider than it is tall.
     */
    jfcalplugin.setAspectRatio("#mycal",0.75);


    /**
     * Initialize previous month button
     */
    $("#BtnPreviousMonth").button();
    $("#BtnPreviousMonth").click(function() {
      jfcalplugin.showPreviousMonth("#mycal");
      var calDate = jfcalplugin.getCurrentDate("#mycal"); // returns Date object
      //var dt = convertDateToLocaleDate(calDate);
      //$("#dateSelect").datepicker("setDate",dt);
      $("#shownMonth").html(gon.translated_months[calDate.getMonth('MM')] + " " + calDate.getFullYear());
      return false;
    });
    /**
     * Initialize next month button
     */
    $("#BtnNextMonth").button();
    $("#BtnNextMonth").click(function() {
      jfcalplugin.showNextMonth("#mycal");
      var calDate = jfcalplugin.getCurrentDate("#mycal"); // returns Date object
      //var dt = convertDateToLocaleDate(calDate);
      //$("#dateSelect").datepicker("setDate",dt);
      $("#shownMonth").html(gon.translated_months[calDate.getMonth('MM')] + " " + calDate.getFullYear());
      return false;
    });

    /**
     * Initialize iCal button
     */
    $("#BtnICalTest").button();
    $("#BtnICalTest").click(function() {
      // Please note that in Google Chrome this will not work with a local file. Chrome prevents AJAX calls
      // from reading local files on disk.
      jfcalplugin.loadICalSource("#mycal",$("#iCalSource").val(),"html");
      return false;
    });

    /**
     * Initialize add event modal form
     */
    $("#add-event-form").dialog({
      autoOpen: false,
      height: 650,
      width: 650,
      modal: true,
      buttons: [
      {
        text: gon.add_reservation,
        click: function() {

          var what = jQuery.trim($("#what").val());

          if(what === ""){
            $( "#dialog_event_description" ).dialog();
          }else{
            var startDtArray = temp_dates["booking-start-output"].split("-");
            var startYear = startDtArray[0];
            var startMonth = startDtArray[1];
            var startDay = startDtArray[2];

            // strip any preceeding 0's
            startMonth = startMonth.replace(/^[0]+/g,"");
            startDay = startDay.replace(/^[0]+/g,"");

            var startHour = jQuery.trim($("#startHour").val());
            var startMin = jQuery.trim($("#startMin").val());
            var startMeridiem = jQuery.trim($("#startMeridiem").val());
            startHour = parseInt(startHour.replace(/^[0]+/g,""));
            if(startMin === "0" || startMin === "00"){
              startMin = 0;
            }else{
              startMin = parseInt(startMin.replace(/^[0]+/g,""));
            }
            if(startMeridiem === "AM" && startHour === 12){
              startHour = 0;
            }else if(startMeridiem === "PM" && startHour < 12){
              startHour = parseInt(startHour) + 12;
            }

            var endDtArray = temp_dates["booking-end-output"].split("-");
            var endYear = endDtArray[0];
            var endMonth = endDtArray[1];
            var endDay = endDtArray[2];
            // strip any preceeding 0's
            endMonth = endMonth.replace(/^[0]+/g,"");
            endDay = endDay.replace(/^[0]+/g,"");

            var endHour = jQuery.trim($("#endHour").val());
            var endMin = jQuery.trim($("#endMin").val());
            var endMeridiem = jQuery.trim($("#endMeridiem").val());
            endHour = parseInt(endHour.replace(/^[0]+/g,""));
            if(endMin === "0" || endMin === "00"){
              endMin = 0;
            }else{
              endMin = parseInt(endMin.replace(/^[0]+/g,""));
            }
            if(endMeridiem === "AM" && endHour === 12){
              endHour = 0;
            }else if(endMeridiem === "PM" && endHour < 12){
              endHour = parseInt(endHour) + 12;
            }

            // Dates use integers
            var startDateObj = new Date(parseInt(startYear),parseInt(startMonth)-1,parseInt(startDay),startHour,startMin,0,0);
            var endDateObj = new Date(parseInt(endYear),parseInt(endMonth)-1,parseInt(endDay),endHour,endMin,0,0);

            // add new event to the calendar
            jfcalplugin.addAgendaItem(
              "#mycal",
              what,
              startDateObj,
              endDateObj,
              false,
              {
                fname: "Santa",
                lname: "Claus",
                leadReindeer: "Rudolph",
                myDate: new Date(),
                myNum: 42
              },
              {
                backgroundColor: $("#colorBackground").val(),
                foregroundColor: $("#colorForeground").val()
              }
            );

            $(this).dialog('close');

          }

        }
      },
      {
        text: gon.cancel_reservation,
        click: function() {
          $(this).dialog('close');
        }
      }],
      open: function(event, ui){
        // initialize start & end date picker
        initializeFromToDatePicker('add-event-form');

        // initialize with the date that was clicked
        $("#startDate").val(clickDate);
        $("#endDate").val(clickDate);

        // put focus on first form input element
        $("#what").focus();
      },
      close: function() {
        // reset form elements when we close so they are fresh when the dialog is opened again.
        $("#startDate").datepicker("destroy");
        $("#endDate").datepicker("destroy");
        $("#startDate").val("");
        $("#endDate").val("");
        $("#startHour option:eq(0)").prop("selected", "selected");
        $("#startMin option:eq(0)").prop("selected", "selected");
        $("#startMeridiem option:eq(0)").prop("selected", "selected");
        $("#endHour option:eq(0)").prop("selected", "selected");
        $("#endMin option:eq(0)").prop("selected", "selected");
        $("#endMeridiem option:eq(0)").prop("selected", "selected");
        $("#what").val("");
        //$("#colorBackground").val("#1040b0");
        //$("#colorForeground").val("#ffffff");
      }
    });

    /**
     * Initialize display event form.
     */
    $("#display-event-form").dialog({
      autoOpen: false,
      height: 400,
      width: 400,
      modal: true,
      buttons: [
        {
          text: "Cancel",
          click: function() {
            $(this).dialog('close');
          }
        },
        {
          text: 'Edit',
          click: function() {

          }
        },
        {
          text : 'Delete',
          click: function() {
            $( "#dialog_confirm_delete" ).dialog({
              resizable: false,
              height:200,
              modal: true,
              buttons: {
                "Delete entry": function() {
                  if(clickAgendaItem != null){
                    jfcalplugin.deleteAgendaItemById("#mycal",clickAgendaItem.agendaId);
                    //jfcalplugin.deleteAgendaItemByDataAttr("#mycal","myNum",42);
                  }
                  $( this ).dialog( "close" );
                },
                Cancel: function() {
                  $( this ).dialog( "close" );
                }
              }
            });
            $( this ).dialog( "close" );
          }
        }
      ],
      open: function(event, ui){
        if(clickAgendaItem != null){
          var title = clickAgendaItem.title;
          var startDate = clickAgendaItem.startDate;
          var endDate = clickAgendaItem.endDate;
          var allDay = clickAgendaItem.allDay;
          var data = clickAgendaItem.data;
          // in our example add agenda modal form we put some fake data in the agenda data. we can retrieve it here.
          $("#display-event-form").append(
            "<br><b>" + title+ "</b><br><br>"
          );
          if(allDay){
            $("#display-event-form").append(
              "(All day event)<br><br>"
            );
          }else{
            $("#display-event-form").append(
              "<b>Starts:</b> " + startDate + "<br>" +
              "<b>Ends:</b> " + endDate + "<br><br>"
            );
          }
          for (var propertyName in data) {
            $("#display-event-form").append("<b>" + propertyName + ":</b> " + data[propertyName] + "<br>");
          }
        }
      },
      close: function() {
        // clear agenda data
        $("#display-event-form").html("");
      }
    });

    /**
     * Initialize our tabs
     */
    $("#tabs").tabs({
      /*
       * Our calendar is initialized in a closed tab so we need to resize it when the example tab opens.
       */
      show: function(event, ui){
        if(ui.index === 1){
          jfcalplugin.doResize("#mycal");
        }
      }
    });

  }

  function add_listings_to_calender(){
    // add new events to the calendar
    gon.transactions.forEach(function(transaction){
      var startArray = transaction.start_on.split("-");
      var endArray = transaction.end_on.split("-");
      var startYear = startArray[0];
      var endYear = endArray[0];
      var startMonth = startArray[1];
      var endMonth = endArray[1];
      var startDay = startArray[2];
      var endDay = endArray[2];
      // strip any preceeding 0's
      startMonth = startMonth.replace(/^[0]+/g,"");
      endMonth = endMonth.replace(/^[0]+/g,"");
      startDay = startDay.replace(/^[0]+/g,"");
      endDay = endDay.replace(/^[0]+/g,"");

      // create Date objects
      var startDateObj = new Date(parseInt(startYear),parseInt(startMonth)-1,parseInt(startDay),0,1,0,0);
      var endDateObj = new Date(parseInt(endYear),parseInt(endMonth)-1,parseInt(endDay),23,59,0,0);
      var createdDateObj = new Date(transaction.created_at);

      jfcalplugin.addAgendaItem(
        "#mycal",
        transaction.title,
        startDateObj,
        endDateObj,
        false,
        {
          "Renting Organization": transaction.renting_organization,
          "Created on": createdDateObj,
        },
        {
          backgroundColor: transaction.color,
          foregroundColor: "white"
        }
      );

      // Set color of listing
      $('div.people-listings:contains(' + transaction.title + ')').css('background-color', transaction.color);
    });
  }

  /**
   * Do something when dragging starts on agenda div
   */
  function myAgendaDragStart(eventObj,divElm,agendaItem){
    // destroy our qtip tooltip
    if(divElm.data("qtip")){
      divElm.qtip("destroy");
    }
  }

  /**
   * Do something when dragging stops on agenda div
   */
  function myAgendaDragStop(eventObj,divElm,agendaItem){
  }

  /**
   * Custom tooltip - use any tooltip library you want to display the agenda data.
   * for this example we use qTip - http://craigsworks.com/projects/qtip/
   *
   * @param divElm - jquery object for agenda div element
   * @param agendaItem - javascript object containing agenda data.
   */
  function myApplyTooltip(divElm,agendaItem){

    // Destroy currrent tooltip if present
    if(divElm.data("qtip")){
      divElm.qtip("destroy");
    }

    var displayData = "";

    var title = agendaItem.title;
    var startDate = agendaItem.startDate;
    var endDate = agendaItem.endDate;
    var allDay = agendaItem.allDay;
    var data = agendaItem.data;
    displayData += "<br><b>" + title+ "</b><br><br>";
    if(allDay){
      displayData += "(All day event)<br><br>";
    }else{
      displayData += "<b>Starts:</b> " + startDate + "<br>" + "<b>Ends:</b> " + endDate + "<br><br>";
    }
    for (var propertyName in data) {
      displayData += "<b>" + propertyName + ":</b> " + data[propertyName] + "<br>";
    }
    // use the user specified colors from the agenda item.
    var backgroundColor = agendaItem.displayProp.backgroundColor;
    var foregroundColor = agendaItem.displayProp.foregroundColor;
    var myStyle = {
      border: {
        width: 5,
        radius: 10
      },
      padding: 10,
      textAlign: "left",
      tip: true,
      name: "dark" // other style properties are inherited from dark theme
    };
    if(backgroundColor !== null && backgroundColor !== ""){
      myStyle["backgroundColor"] = backgroundColor;
    }
    if(foregroundColor !== null && foregroundColor !== ""){
      myStyle["color"] = foregroundColor;
    }
    // apply tooltip
    divElm.qtip({
      content: displayData,
      position: {
        corner: {
          tooltip: "bottomMiddle",
          target: "topMiddle"
        },
        adjust: {
          mouse: true,
          x: 0,
          y: -15
        },
        target: "mouse"
      },
      show: {
        when: {
          event: 'mouseover'
        }
      },
      style: myStyle
    });

  }

  /**
   * Called when user clicks day cell
   * use reference to plugin object to add agenda item
   */
  function myDayClickHandler(eventObj){
    // Get the Date of the day that was clicked from the event object
    var date = eventObj.data.calDayDate;
    // store date in our global js variable for access later
    clickDate = convertDateToLocaleDate(date);

    temp_dates["booking-start-output"] = ST.utils.toISODate(date);
    temp_dates["booking-end-output"] = ST.utils.toISODate(date);

    // open our add event dialog
    $('#add-event-form').dialog('open');
  }

  /**
   * Called when user clicks and agenda item
   * use reference to plugin object to edit agenda item
   */
  function myAgendaClickHandler(eventObj){
    // Get ID of the agenda item from the event object
    var agendaId = eventObj.data.agendaId;
    // pull agenda item from calendar
    var agendaItem = jfcalplugin.getAgendaItemById("#mycal",agendaId);
    clickAgendaItem = agendaItem;
    $("#display-event-form").dialog('open');
  }

  /**
   * Called when user drops an agenda item into a day cell.
   */
  function myAgendaDropHandler(eventObj){
    // Get ID of the agenda item from the event object
    var agendaId = eventObj.data.agendaId;
    // date agenda item was dropped onto
    var date = eventObj.data.calDayDate;
    // Pull agenda item from calendar
    var agendaItem = jfcalplugin.getAgendaItemById("#mycal",agendaId);
  }

  /**
   * Called when a user mouses over an agenda item
   */
  function myAgendaMouseoverHandler(eventObj){
    var agendaId = eventObj.data.agendaId;
    var agendaItem = jfcalplugin.getAgendaItemById("#mycal",agendaId);
  }

  function convertDateToLocaleDate(date){
    var d;
    if (gon.locale === "en"){
      d = ('0' + (date.getMonth()+1)).slice(-2) + "/" + ('0' + date.getDate()).slice(-2) + "/" + date.getFullYear();
    }else if (gon.locale === "de"){
      d = ('0' + date.getDate()).slice(-2) + "." + ('0' + (date.getMonth()+1)).slice(-2) + "." + date.getFullYear();
    }else {
      d = date.getFullYear() + "-" + ('0' + (date.getMonth()+1)).slice(-2) + "-" + ('0' + date.getDate()).slice(-2);
    }
    return d;
  }

  return {
    init: init,
    initializeDatepicker: initializeDatepicker,
    initializeGantt: initializeGantt
  };
};
