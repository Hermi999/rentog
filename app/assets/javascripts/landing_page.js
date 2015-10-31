window.ST = window.ST || {};

(function(module) {

  // Add method to window.ST object
  module.initialize_landingpage = function(){
    $('.page-content').css('padding-bottom', '0px');

    // calculate the size of the videos
    size_video();

    // resize video width if window is resized
    $(window).resize(function(){
      size_video();
    });
  };



  var calc_video_width = function(){
    var video_width = 1080;
    var max_video_width = $( document ).width() - 10;

    if (video_width > max_video_width){
      return max_video_width;
    }else{
      return video_width;
    }
  };

  var size_video = function(){
    // video ratio
    var ratio = 1.6;

    // calculate video with
    var video_width = calc_video_width();

    // Show videos with colorbox
    $(".create_listing_youtube").colorbox({iframe:true, innerWidth:video_width, innerHeight:video_width/ratio});
    $(".book_a_listing_youtube").colorbox({iframe:true, innerWidth:video_width, innerHeight:video_width/ratio});
  };
})(window.ST);
