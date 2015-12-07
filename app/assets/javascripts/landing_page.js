/* Tell jshint that there exist globals */
/* globals gon, size_video, initialize_contact_me_form, initialize_newsletter_subscribe_form, initialize_voucher_subscribe_form */
/* jshint unused: false */

window.ST = window.ST || {};

(function(module) {

  // Add method to window.ST object
  module.initialize_landingpage = function(){
    $('.page-content').css('padding-bottom', '0px');

    // calculate the size of the videos
    size_video(["how_it_works_video"]);

    // resize video width if window is resized
    $(window).resize(function(){
        size_video(["how_it_works_video"]);
    });

    $(".newsletter-popover").colorbox({inline:true, width:"500px", height: "330px", transition: "none"});

    /*
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
    */

    // Show contact me form
    $('.contactme').on('click', function(ev){
        $('#contact_me_form').toggle();
        ev.preventDefault();
    });

    // Initialize forms
    initialize_contact_me_form();
    initialize_newsletter_subscribe_form();
    initialize_voucher_subscribe_form();
  };

})(window.ST);
