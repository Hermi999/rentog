/* globals console, readCookie, createCookie */

window.ST = window.ST || {};

(function(module) {
  module.listing = function() {
    // Initialize listing-request button
    if ($('#listing-request-button-show-form').length > 0){
      $('#listing-request-button-show-form').click(function(ev){
        ev.preventDefault();
        $('#listing-side-bar-wrapper').animate({ "right": "0px" });
      });
    }

    // Initialize short keys
    $("body").keypress(function(ev){
      if(document.activeElement.localName === "body"){
        var key = ev.keyCode || ev.key;
        console.log(key);

        // a ... show all devices
        if(key === 97 || key === "a"){
          window.location = $('#show-all-devices')[0].href;
        }

        // b ... back to filter
        if(key === 98 || key === "b"){
          window.location = $('#listing_back_button')[0].href;
        }

        // p ... previous
        if(key === 112 || key === "p"){
          window.location = $('#listing-nav-left')[0].href;
        }

        // n ... next
        if(key === 110 || key === "n"){
          window.location = $('#listing-nav-right')[0].href;
        }
      }
    });

    // Initialize Tooltips
    var tableContent = $('#keyboard-nav-table-content').html();
    $('#keyboard-navigation-button').webuiPopover({content: tableContent, animation:'fade', placement:'bottom-left', "data-placement": 'vertical', trigger:'click', style: "listing-popover-style"});


    // load listing ids from next page if on the page before the last listing
    var current_page = Number(readCookie("current_page"));
    if (readCookie("count_listing_pages") > 1 && Number(readCookie("count_listing_pages")) > current_page){

      if ($('#listing-nav-right').data("forelast-listing") === true){

      $.get( location.protocol + "//" + location.host + "/marketplace?view=list&getListingIds=true&page=" + (current_page+1), function(data) {
        var listings = readCookie("listings");
        for (var i in data.listing_ids){
          listings += "&" + data.listing_ids[i];
        }
        createCookie("listings", listings, 999);
        createCookie("current_page", current_page + 1, 999);
      })
        .done(function() {

        })
        .fail(function() {

        })
        .always(function() {

        });
      }
    }


    $('#add-to-updates-email').on('click', function() {
      var text = $(this).find('#add-to-updates-email-text');
      var actionLoading = text.data('action-loading');
      var actionSuccess = text.data('action-success');
      var actionError = text.data('action-error');
      var url = $(this).attr('href');

      text.html(actionLoading);

      $.ajax({
        url: url,
        type: "PUT",
      }).done(function() {
        text.html(actionSuccess);
      }).fail(function() {
        text.html(actionError);
      });
    });
  };

  module.initializeQuantityValidation = function(opts) {
    jQuery.validator.addMethod(
      "positiveIntegers",
      function(value) {
        return (value % 1) === 0 && value > 0;
      },
      jQuery.validator.format(opts.errorMessage)
    );

    // add rule to input
    $('#'+opts.input).rules("add", {
      positiveIntegers: true
    });
  };

  module.initializeShippingPriceTotal = function(quantityInputSelector, shippingPriceSelector, decimalMark){
    var $quantityInput = $(quantityInputSelector);
    var $shippingPriceElements = $(shippingPriceSelector);

    var updateShippingPrice = function() {
      $shippingPriceElements.each(function(index, shippingPriceElement) {
        var $priceEl = $(shippingPriceElement);
        var shippingPriceCents = $priceEl.data('shipping-price') || 0;
        var perAdditionalCents = $priceEl.data('per-additional') || 0;
        var quantity = parseInt($quantityInput.val() || 0);
        var additionalCount = Math.max(0, quantity - 1);

        // To avoid floating point issues, do calculations in cents
        var newShippingPrice = shippingPriceCents + perAdditionalCents * additionalCount;
        var priceText = (newShippingPrice / 100).toFixed(2) + "";
        var priceTextWithDecimalMark = priceText.replace(".", decimalMark);

        $priceEl.text(priceTextWithDecimalMark);
      });
    };

    $quantityInput.on("keyup change", updateShippingPrice); // change for up and down arrows
    updateShippingPrice();
  };

})(window.ST);
