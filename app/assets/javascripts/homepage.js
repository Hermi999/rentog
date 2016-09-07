window.ST.initializeListingRequestButtons = function(){
  // Initialize listing reqest
  if($('.listing_wrapper')){
    $('.listing_wrapper').hover(
      function(ev){
        $(ev.currentTarget).find('.listings-request-slider').show();
        $(ev.currentTarget).find('.listings-request-slider2').show();
      },
      function(ev){
        $(ev.currentTarget).find('.listings-request-slider').hide();
        $(ev.currentTarget).find('.listings-request-slider2').hide();
      }
    );
  }

  if($('.listings-request-slider').length > 0){
    $('.listings-request-slider').click(function(ev){
      ev.preventDefault();
      listing_id = ev.currentTarget.dataset.listingid;
      $('#listing_request_listing_id').val(listing_id);
      $('#listing-side-bar-wrapper').animate({ "right": "0px" });
    });
  }

  // Initialize listing request button listview
  if ($('.listing_request_button').length > 0){
    $('.listing_request_button').click(function(ev){
      ev.preventDefault();
      listing_id = ev.currentTarget.dataset.listingId;
      $('#listing_request_listing_id').val(listing_id);
      $('#listing-side-bar-wrapper').animate({ "right": "0px" });
    });
  }

  // Initialize "no listing - request form"
  if ($('#dummy_form_message').length > 0){
    $('#dummy_form_message')[0].value = $('#q')[0].value;
  }

  // Copy values from dummy form to listing request form. This is necessary because
  // we cant have the listing request form within the search formular - That wouldnt
  // be valid html
  $("#dummy-listing-request-button").click(function(e){
    e.preventDefault();

    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    var _return = false;

    // Check values of dummy form
    if ($("#dummy_form_email")[0].value === ""){
      $("#dummy_form_email").css("background-color", "#E91E63");
      _return = true;
    }
    // Validate email
    else if (re.test($("#dummy_form_email")[0].value) === false){
      $("#dummy_form_email").css("background-color", "#E91E63");
      _return = true;
    }
    else{
      $("#dummy_form_email").css("background-color", "white");
    }

    if ($("#dummy_form_name")[0].value === ""){
      $("#dummy_form_name").css("background-color", "#E91E63");
      _return = true;
    }else{
      $("#dummy_form_name").css("background-color", "white");
    }

    if ($("#dummy_form_country")[0].value === ""){
      $("#dummy_form_country").css("background-color", "#E91E63");
      _return = true;
    }else{
      $("#dummy_form_country").css("background-color", "white");
    }

    if (_return) { return false; }


    // Copy values to real listing request form
    $("#listing_request_name")[0].value = $('#dummy_form_name')[0].value;
    $("#listing_request_listing_id")[0].value = "abcd";
    $("#listing_request_email")[0].value = $('#dummy_form_email')[0].value;
    $("#listing_request_phone")[0].value = $('#dummy_form_phone')[0].value;
    $("#listing_request_country")[0].value = $('#dummy_form_country')[0].value;
    $("#listing_request_message")[0].value = $('#dummy_form_message')[0].value;
    $("#listing_request_contact_per_phone")[0].checked = $("#dummy_form_contact_per_phone")[0].checked;
    $("#listing_request_get_further_docs")[0].checked = $("#dummy_form_get_further_docs")[0].checked;
    $("#listing_request_get_price_list")[0].checked = $("#dummy_form_get_price_list")[0].checked;
    $("#listing_request_get_quotation")[0].checked = $("#dummy_form_get_quotation")[0].checked;
    $("#g-recaptcha-response")[0].value = "abcd";

    // Disable button
    $("#dummy-listing-request-button").addClass("disabledbutton");

    // Submit listing request form
    $("#listing-request-button").click();
  });


  $('.add-to-wishlist').unbind('click');
  $('.remove-from-wishlist').unbind('click');

  // Initialize add to wishlist
  $('.add-to-wishlist').click(function(ev){
    ev.preventDefault();
    var el = $(ev.currentTarget);
    var listing_id = el.data("listing-id");
    var listings = "";
    var existing_listing_ids = readCookie("wishlist");

    if (existing_listing_ids === null){
      listings = listing_id;
      createCookie("wishlist", listings, 9999);
      ST.js_notifications.triggerNotification("success", "Done!");
      el.hide();
      $(el.parent()[0]).find('.remove-from-wishlist').show();

    }else{
      existing_listing_ids_arr = existing_listing_ids.split("&");

      var already_there = false;
      for(var i in existing_listing_ids_arr){
        if (Number(existing_listing_ids_arr[i]) === listing_id){
          already_there = true;
          break;
        }
      }

      if (already_there == false){
        listings = existing_listing_ids + "&" + listing_id;
        createCookie("wishlist", listings, 9999);
        el.hide();
        $(el.parent()[0]).find('.remove-from-wishlist').show();
        ST.js_notifications.triggerNotification("success", "Done!");
      }else{
        ST.js_notifications.triggerNotification("warning", "Already there!");
      }
    }
  });

  $('.remove-from-wishlist').click(function(ev){
    ev.preventDefault();
    var el = $(ev.currentTarget);
    var listing_id = el.data("listing-id");
    var listings = "";
    var existing_listing_ids = readCookie("wishlist");

    existing_listing_ids_arr = existing_listing_ids.split("&");

    for(var i in existing_listing_ids_arr){
      if (Number(existing_listing_ids_arr[i]) === listing_id){
        existing_listing_ids_arr.splice(Number(i), 1);
        ST.js_notifications.triggerNotification("info", "Removed!");
        el.hide();
        $(el.parent()[0]).find('.add-to-wishlist').show();
        createCookie("wishlist", existing_listing_ids_arr.join("&"), 9999);

        if (getUrlParameter('view') === "wishlist"){
          el.parent().parent().parent().parent().hide();
        }
        return;
      }
    }

    ST.js_notifications.triggerNotification("alert", "Already removed!");

  });
}



$(function() {

  window.ST.initializeListingRequestButtons();

  // Selectors
  var showFiltersButtonSelector = "#home-toolbar-show-filters";
  var filtersContainerSelector = "#home-toolbar-filters";

  // Elements
  var $showFiltersButton = $(showFiltersButtonSelector);
  var $filtersContainer = $(filtersContainerSelector);

  $showFiltersButton.click(function() {
    $showFiltersButton.toggleClass("selected");
    $filtersContainer.toggleClass("home-toolbar-filters-mobile-hidden");
  });

  // Relocate filters
  if ($("#filters").length && $("#desktop-filters").length) {
    relocate(768, $("#filters"), $("#desktop-filters").get(0));
  }

  relocate(768, $("#header-menu-mobile-anchor"), $("#header-menu-desktop-anchor").get(0));
  relocate(768, $("#header-user-mobile-anchor"), $("#header-user-desktop-anchor").get(0));

  $('.grid-item-share').click(function(ev){
    $($(ev.target.parentNode).children()[1]).show();
  });
  $('.share-listing').click(function(ev){
    $($(ev.target.parentNode.parentNode).children()[1]).show();
  });
  $('.home-list-share').click(function(ev){
    $(ev.target.nextElementSibling).show();
  });

  $('.share-dialog').mouseleave(function(ev){
    $('.share-dialog').hide();
  });

  $('.link-dialog').mouseleave(function(ev){
    $('.link-dialog').hide();
    $('.share-dialog').hide();
  });

  $('.homepage-listing-link-button').click(function(ev){
    ev.preventDefault();
    $(ev.target.parentNode.parentNode.parentNode.nextElementSibling).toggle();
  });


  /************** Homepage - Custom Field Options popover ****************/
  function insertCustomFieldOptionData(field_id){
    var content = $('#cf_options_content_' + field_id);
    var data = window.ST.load_custom_field_options[field_id];
    var id_prefix = 'filter_option_';
    if (data.type === "CheckboxField"){
      id_prefix = 'checkbox_filter_option_';
    }
    $.each(data.options, function(index, value){
      if ($("#" + id_prefix + value.id)[0]){

      }else{
        var checked = "";
        if (getUrlParameter(id_prefix + value.id) === value.id.toString()){
          checked = "checked='checked'";
        }

        content.append($('<div class="custom-filter-checkbox-container2">')
                .append($('<label class="custom-filter-checkbox-label">')
                  .append('<input type="checkbox" name="' + id_prefix + value.id + '" id="' + id_prefix + value.id + '" value="' + value.id + '" class="field_id_' + field_id + '" ' + checked + '>')
                  .append('<span class="custom-filter-checkbox-label-text">'+ value.title +'</span><span class="manufacturer_count"> (' + value.count + ')</span>')));
      }
    });

    function compare_options(a,b) {
      if (a.title.toLowerCase < b.title.toLowerCase) return -1;
      if (a.title.toLowerCase > b.title.toLowerCase) return 1;
      return 0;
    }
  }

  $('.all_custom_field_options_close').click(function(ev){
    ev.preventDefault();
    $('body').css('overflow-y', 'visible');
    $('.all_custom_field_options').hide();
  });

  // Load huge custom fields if user hovers with the mouse
  $('.show_more_options').parent().parent().parent().hover(function(ev){
    var _link = $(ev.currentTarget).find('.show_more_options');
    var field_id  = _link.data('fieldId');
    var locale  = _link.data('locale');

    if (!window.ST.load_custom_field_options || !window.ST.load_custom_field_options[field_id]){
      if (!window.ST.load_custom_field_options){
        window.ST.load_custom_field_options = {};
        window.ST.load_custom_field_options[field_id] = true;

      }else if (!window.ST.load_custom_field_options[field_id]) {
        window.ST.load_custom_field_options[field_id] = true;
      }

      $.get('/load_custom_field_options', {custom_field_id: field_id, locale: locale}, function(data){
        window.ST.load_custom_field_options[data.field_id] = data;

        insertCustomFieldOptionData(field_id);
      });
    }
  });


  $('.show_more_options').click(function(ev){
    ev.preventDefault();
    var field_id = ev.currentTarget.dataset.fieldId;
    var locale  = ev.currentTarget.dataset.locale;
    var field_title = ev.currentTarget.dataset.title;
    var custom_field_container = $(ev.currentTarget).parent().find('input');

    // This options have not been loaded (and also not started)
    if (!window.ST.load_custom_field_options || !window.ST.load_custom_field_options[field_id]){
      // No options have been loaded yet
      if (!window.ST.load_custom_field_options){
        window.ST.load_custom_field_options = {};
      // other options have already been loaded
      }else{
        window.ST.load_custom_field_options[field_id] = true;
      }

      $('.all_custom_field_options').hide();
      $('#cf_options_' + field_id).show();
      if ($(window).outerHeight() < 700){
        $('body').css('overflow-y', 'hidden');
      }
      $('#cf_options_title_' + field_id).html(field_title);

      $.get('/load_custom_field_options', {custom_field_id: field_id, locale: locale}, function(data){
        window.ST.load_custom_field_options[data.field_id] = data;
        insertCustomFieldOptionData(field_id);
      });
    }

    // content is loading but not finished
    else if (window.ST.load_custom_field_options[field_id] === true){
      $('.all_custom_field_options').hide();
      $('#cf_options_' + field_id).show();
      if ($(window).outerHeight() < 700){
        $('body').css('overflow-y', 'hidden');
      }
      $('#cf_options_title_' + field_id).html(field_title);

    // content for this option has not been loaded yet
    }
    else{
      $('.all_custom_field_options').hide();
      $('#cf_options_' + field_id).show();
      if ($(window).outerHeight() < 700){
        $('body').css('overflow-y', 'hidden');
      }
      $('#cf_options_title_' + field_id).html(field_title);
      insertCustomFieldOptionData(field_id);
    }

    // Check selected boxex
    /*$.each(custom_field_container, function(index, val){
      var state = $(val).prop('checked');
      $("#" + val.id).prop('checked', state);
    });*/

  });

  $('.all_custom_field_options_filter').keyup(function(ev){
    $(ev.currentTarget).parent().parent().parent().find(".all_custom_field_options_checked").find("input").prop('checked', false);

    var val = $(ev.currentTarget).val();
    $.each($(ev.currentTarget).parent().parent().parent().find('.custom-filter-checkbox-label-text'), function(index, value){
      if (value.textContent.toLowerCase().indexOf(val.toLowerCase()) > -1){
        $(value).parent().show();
      }else{
        $(value).parent().hide();
      }
    });
  });

  $('.all_custom_field_options_checked').click(function(ev){
    $(ev.currentTarget).parent().parent().parent().find('.all_custom_field_options_filter').val("");

    $.each($(ev.currentTarget).parent().parent().parent().find('.custom-filter-checkbox-label').find('input'), function(index, value){
      if ($(ev.currentTarget).find("input").prop('checked') === true){
        if (value.checked === false){
          $(value).parent().hide();
        }
      }else{
        $(value).parent().show();
      }
    });
  });
});


// Delayed loading of huge custom fields after page is fully loaded (incl. js), only if not already needed
$(window).load(function() {
  setTimeout(function(){
    if (!window.ST.load_custom_field_options){
      window.ST.load_custom_field_options = {};
      $.each($('.show_more_options'), function(index, value){
        var field_id = value.dataset.fieldId;
        var locale  = value.dataset.locale;
        window.ST.load_custom_field_options[field_id] = true;

        $.get('/load_custom_field_options', {custom_field_id: field_id, locale: locale}, function(data){
          window.ST.load_custom_field_options[data.field_id] = data;
        });

      });
    }else{
      $.each($('.show_more_options'), function(index, value){
        var field_id = value.dataset.fieldId;
        var locale  = value.dataset.locale;
        if (!window.ST.load_custom_field_options[field_id]){
          window.ST.load_custom_field_options[field_id] = true;

          $.get('/load_custom_field_options', {custom_field_id: field_id, locale: locale}, function(data){
            window.ST.load_custom_field_options[data.field_id] = data;
          });
        }
      });
    }
  }, 10000);
});
