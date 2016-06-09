function closeDevelopmentInfos(){
  if ($('#development-infos-close').length > 0){
    $('#development-infos-close').click(function(){
      $('#development-infos').fadeOut();
    });
  }
}
closeDevelopmentInfos();


// change background color of site based on relation
function change_background_based_on_relation(){
  if ($(".other_company_is_site_owner").length){
    var color_background = "rgb(230, 239, 253)";
    var color_title_container = "rgb(128, 153, 191)";

    $('body').css('background-color', color_background);
    $('.page-content').css('background-color', color_background);
    $('.wrapper').css('background-color', color_background);
    $('.title-container').css('background-color', color_title_container);
    $('.marketplace-title-header>h1').css("color", "white");
  }
};
change_background_based_on_relation();


// Get environment, production or development
var getEnvironment = function(){
  if (window.location.hostname === "tools.rentog.com"){
    return "production";
  }
  else{
    return "development";
  }
};
var rentog_environment = getEnvironment();


// Get URL Parameters
var getUrlParameter = function(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
};


// extend Date object
Date.prototype._addDays = function(days) {
     var dat = new Date(this.valueOf())
     dat.setDate(dat.getDate() + days);
     return dat;
}


function getDatesBetweenRange(startDate, stopDate) {
  var dateArray = new Array();
  var currentDate = startDate;
  while (currentDate <= stopDate) {
    dateArray.push(currentDate)
    currentDate = currentDate._addDays(1);
  }
  return dateArray;
}

function getDaysBetweenDates(startDate, endDate){
  var oneDay = 24*60*60*1000; // hours*minutes*seconds*milliseconds
  var firstDate = endDate;
  var secondDate = startDate;

  return Math.floor(Math.abs((firstDate.getTime() - secondDate.getTime())/(oneDay)));
}


var calc_video_width = function(){
    var video_width = 1080;
    var max_video_width = $( window ).width() - 10;

    if (video_width > max_video_width){
      return max_video_width;
    }else{
      return video_width;
    }
  };

var size_video = function(video_classes){
  // video ratio
  var ratio = 1.6;

  // calculate video with
  var video_width = calc_video_width();

  // Show videos with colorbox
  for (var i=0; i<video_classes.length; i++){
    $("." + video_classes[i]).colorbox({iframe:true, innerWidth:video_width, innerHeight:video_width/ratio});
  }
};


function initialize_confirmation_pending_form(locale, email_in_use_message) {
  $('#mistyped_email_link').click(function() {
    $('#password_forgotten').slideToggle('fast');
    $("html, body").animate({ scrollTop: $(document).height() }, 1000);
    $('input.email').focus();
  });
  var form_id = "#change_mistyped_email_form";
  $(form_id).validate({
     errorPlacement: function(error, element) {
       error.insertAfter(element);
     },
     rules: {
       "person[email]": {required: true, email: true, remote: "/people/check_email_availability_and_validity"}
     },
     messages: {
       "person[email]": { remote: email_in_use_message }
     },
     onkeyup: false, //Only do validations when form focus changes to avoid exessive calls
     submitHandler: function(form) {
       disable_and_submit(form_id, form, "false", locale);
     }
  });
}

/* This should be used with non-ajax forms only */
function disable_and_submit(form_id, form, ajax, locale) {
  disable_submit_button(form_id, locale);
  form.submit();
}

/* This should be used always with ajax forms */
function prepare_ajax_form(form_id, locale, rules, messages) {
  $(form_id).ajaxForm({
    dataType: 'script',
    beforeSubmit: function() {
      $(form_id).validate({
        rules: rules,
        messages: messages
      });
      if ($(form_id).valid() == true) {
        disable_submit_button(form_id, locale);
      }
      return $(form_id).valid();
    }
  });
}

function disable_submit_button(form_id) {
  $(form_id).find("button").attr('disabled', 'disabled');

  var json = ST.jsonTranslations;
  $(form_id).find("button").text(json.please_wait);
}

function auto_resize_text_areas(class_name) {
  $('textarea.' + class_name).autosize();
}

function translate_validation_messages(locale) {
  function formatMinMaxMessage(message) {
    return function(otherName) {
      var otherVal = ST.utils.findElementByName(otherName).val();
      return jQuery.validator.format(message, otherVal);
    }
  }

  var json = ST.jsonTranslations;
  jQuery.extend(jQuery.validator.messages, {
      required: json.validation_messages.required,
      remote: json.validation_messages.remote,
      email: json.validation_messages.email,
      url: json.validation_messages.url,
      date: json.validation_messages.date,
      dateISO: json.validation_messages.dateISO,
      number: json.validation_messages.number,
      digits: json.validation_messages.digits,
      creditcard: json.validation_messages.creditcard,
      equalTo: json.validation_messages.equalTo,
      accept: json.validation_messages.accept,
      maxlength: jQuery.validator.format(json.validation_messages.maxlength),
      minlength: jQuery.validator.format(json.validation_messages.minlength),
      rangelength: jQuery.validator.format(json.validation_messages.rangelength),
      range: jQuery.validator.format(json.validation_messages.range),
      max: jQuery.validator.format(json.validation_messages.max),
      min: jQuery.validator.format(json.validation_messages.min),
      address_validator: jQuery.validator.format(json.validation_messages.address_validator),
      money: jQuery.validator.format(json.validation_messages.money),
      min_bound: formatMinMaxMessage(json.validation_messages.min_bound),
      max_bound: formatMinMaxMessage(json.validation_messages.max_bound),
      number_min: jQuery.validator.format(json.validation_messages.min),
      number_max: jQuery.validator.format(json.validation_messages.max),
      number_no_decimals: json.validation_messages.number_no_decimals,
      number_decimals: json.validation_messages.number_decimals,
      number_conditional_decimals: json.validation_messages.number
  });
}
