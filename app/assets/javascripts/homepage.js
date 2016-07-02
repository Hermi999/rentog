$(function() {
  // Initialize listing reqest
  if($('.listing_wrapper')){
    $('.listing_wrapper').hover(
      function(ev){
        $(ev.currentTarget).find('.listings-request-slider').show();
      },
      function(ev){
        $(ev.currentTarget).find('.listings-request-slider').hide();
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
});
