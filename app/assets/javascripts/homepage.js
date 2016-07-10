$(function() {
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
                  .append('<span class="custom-filter-checkbox-label-text">'+ value.title +'</span>')));
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
    $('.all_custom_field_options').hide();
  });

  // Load huge custom fields if user hovers with the mouse
  $('.show_more_options').parent().parent().parent().hover(function(ev){
    var field_id  = $(ev.currentTarget).find('.show_more_options').data('fieldId');

    if (!window.ST.load_custom_field_options || !window.ST.load_custom_field_options[field_id]){
      if (!window.ST.load_custom_field_options){
        window.ST.load_custom_field_options = {};
        window.ST.load_custom_field_options[field_id] = true;

      }else if (!window.ST.load_custom_field_options[field_id]) {
        window.ST.load_custom_field_options[field_id] = true;
      }

      $.get('/load_custom_field_options', {custom_field_id: field_id}, function(data){
        window.ST.load_custom_field_options[data.field_id] = data;

        insertCustomFieldOptionData(field_id);
      });
    }
  });


  $('.show_more_options').click(function(ev){
    ev.preventDefault();
    var field_id = ev.currentTarget.dataset.fieldId;
    var field_title = ev.currentTarget.dataset.title;
    var custom_field_container = $(ev.currentTarget).parent().find('input');

    if (!window.ST.load_custom_field_options || !window.ST.load_custom_field_options[field_id]){
      // No options has been loaded yet
      if (!window.ST.load_custom_field_options){
        window.ST.load_custom_field_options = {};
      }else{
        window.ST.load_custom_field_options[field_id] = true;
      }

      $('.all_custom_field_options').hide();
      $('#cf_options_' + field_id).show();
      $('#cf_options_title_' + field_id).html(field_title);

      $.get('/load_custom_field_options', {custom_field_id: field_id}, function(data){
        window.ST.load_custom_field_options[data.field_id] = data;
        insertCustomFieldOptionData(field_id);
      });
    }
    // content is loading but not finished
    else if (window.ST.load_custom_field_options[field_id] === true){

    // content for this option has not been loaded yet
    }
    else{
      $('.all_custom_field_options').hide();
      $('#cf_options_' + field_id).show();
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
        window.ST.load_custom_field_options[field_id] = true;

        $.get('/load_custom_field_options', {custom_field_id: field_id}, function(data){
          window.ST.load_custom_field_options[data.field_id] = data;
        });

      });
    }else{
      $.each($('.show_more_options'), function(index, value){
        var field_id = value.dataset.fieldId;
        if (!window.ST.load_custom_field_options[field_id]){
          window.ST.load_custom_field_options[field_id] = true;

          $.get('/load_custom_field_options', {custom_field_id: field_id}, function(data){
            window.ST.load_custom_field_options[data.field_id] = data;
          });
        }
      });
    }
  }, 10000);
});
