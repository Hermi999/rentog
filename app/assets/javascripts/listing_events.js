/* Tell jshint that there exists a global called gon */
/* globals gon, getUrlParameter, console */
/* jshint unused: false */

window.ST = window.ST || {};

window.ST.listingEvents = (function() {
  var loadAllowed = true;
  var listing_id = "";

  function init(username){

    var timelineBlocks = $('.cd-timeline-block'),
        offset = 0.8;

    // helper functions
    function formatState (state) {
      if (!state.id || !window.listing_images[state.element.value]) { return state.text; }
      var $state = $(
        '<span class="timeline-listing-img-wrapper"><img src=' + window.listing_images[state.element.value] + ' class="timeline-listing-img" /><span class="timeline-listing-text">' + state.text + '</span></span>'
      );
      return $state;
    }

    function suc_func(){
      $('.cd-container').empty();
    }


    //hide timeline blocks which are outside the viewport
    hideBlocks(timelineBlocks, offset);

    // show message if no events yet
    if (timelineBlocks.length === 0){
      $('#cd-timeline-no-events').show();
      $('#cd-timeline').hide();
    }else{
      $('#cd-timeline-no-events').hide();
      $('#cd-timeline').show();
    }

    //on scolling, show/animate timeline blocks when enter the viewport
    $(window).on('scroll', function(){
      if (!window.requestAnimationFrame){
        setTimeout(function(){ showBlocks(timelineBlocks, offset); }, 100);
      }else{
        window.requestAnimationFrame(function(){ showBlocks(timelineBlocks, offset); });
      }
    });

    $(window).on('scroll', function(){
      // if nearly at the end, then try to load data
      if(loadAllowed && $(window).scrollTop() > ($('body').height()-$(window).height()*2)){
        // get number of elements
        var offset = $('.cd-timeline-block').length;
        if (listing_id === ""){
          getElementsWithOffset(offset, username);
        }else{
          getElementsWithOffset(offset, username, null);
        }

      }
    });


    // if listing id was given as url parameter
    var _listing_id = getUrlParameter('listing_id');
    if (typeof _listing_id !== "undefined"){
      listing_id = _listing_id;
      $("#listings_listing_id option[value='"+ listing_id +"']").attr('selected',true);
    }


    // listing dropdown
    jQuery(".js-example-basic-single").select2({
        placeholder: "Choose device",
        allowClear: true,
        templateResult: formatState
      });

    // On dropdown change
    $('#listings_listing_id').change(function(ev){
      listing_id = ev.currentTarget.value;

      if (listing_id === ""){
        getElementsWithOffset(0, username, suc_func);
      }else{
        getElementsWithOffset(0, username, suc_func);
      }
    });
  }


  function hideBlocks(blocks, offset) {
    blocks.each(function(){
      if ($(this).offset().top > $(window).scrollTop()+$(window).height()*offset)
      {
        $(this).find('.cd-timeline-img, .cd-timeline-content').addClass('is-hidden');
      }
    });
  }


  function showBlocks(blocks, offset) {
    blocks.each(function(){
      if ($(this).offset().top <= $(window).scrollTop()+$(window).height()*offset){
        if ($(this).find('.cd-timeline-img').hasClass('is-hidden')){
          $(this).find('.cd-timeline-img, .cd-timeline-content').removeClass('is-hidden').addClass('bounce-in');
        }
      }
    });
  }

  function getElementsWithOffset(offset, username, success_func){
    loadAllowed = false;

    var params = "";
    if (listing_id !== ""){
      params = "?listing_id=" + listing_id;
    }

    $.ajax({
      dataType: "html",
      url: "/" + username + "/more_listing_events" + params,
      data: {offset: offset}
    })
    .success(function(data){
      if (success_func){
        success_func();
      }

      // Do not show any message to user
      $('.cd-container').append(data);
      if(data !== ""){
        loadAllowed = true;
      }else{
        loadAllowed = false;
      }

      var timelineBlocks = $('.cd-timeline-block');

      // show message if no events yet
      if (timelineBlocks.length === 0){
        $('#cd-timeline-no-events').show();
        $('#cd-timeline').hide();
      }else{
        $('#cd-timeline-no-events').hide();
        $('#cd-timeline').show();
      }
    })
    .error(function(data){
      // Do not show any message to user
    });
  }

  return {
    init: init
  };
})();
