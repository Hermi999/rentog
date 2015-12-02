window.ST = window.ST || {};

(function(module) {

  // Add method to window.ST object
  module.initialize_landingpage = function(){
    $('.page-content').css('padding-bottom', '0px');

    // // calculate the size of the videos
    // size_video(["create_listing_youtube", "book_a_listing_youtube"]);

    // // resize video width if window is resized
    // $(window).resize(function(){
    //   size_video();
    // });


    // Scroll down to video on click on 'how it works'
    $("#scrollToVideo").click(function(ev) {
        // scroll to video
        $('html, body').animate({
            scrollTop: $("#landing_page_video").offset().top
        }, 2000);

        // Do not follow link (this is old)
        ev.preventDefault();

        // Autoplay video
        $("#landing_page_video")[0].src += "&autoplay=1";
    });
  };

})(window.ST);
