/* Tell jshint that there exists a global called gon */
/* globals gon, getUrlParameter, console */
/* jshint unused: false */

window.ST = window.ST || {};

window.ST.importListings = (function() {
  function init(){
    // FULLSCREEN
    $('.header-wrapper').addClass('fullscreen');
    $('.title-header-wrapper').addClass('fullscreen');
    $('.page-content .wrapper').addClass('fullscreen');

    $.fn.hasScrollBar = function() {
        return this.get(0).scrollHeight > this.height();
    }

    $('.td-scroll').hover(function(ev){
      if($(ev.currentTarget).text() != ""){
        $('#large_text').html($(ev.currentTarget).html());
        $('#large_text').css('left', $(ev.currentTarget).position().left);
        $('#large_text').css('top', $(ev.currentTarget).position().top + $(ev.currentTarget).height() + 10);
        $('#large_text').show();
      }
    },function(ev){
      setTimeout(function(){
        if ($('#large_text:hover').length <= 0 && $('.td-scroll:hover').length <= 0){
          $('#large_text').hide();
        }
      }, 100);

    });

    $('#large_text').hover(function(ev){},function(){
      $('#large_text').hide();
    });
  }

  return {
    init: init
  };
})();
