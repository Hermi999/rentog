/* Tell jshint that there exists a global called "gon" */
/* globals gon, size_video */
/* jshint unused: false */

window.ST = window.ST || {};

(function(module) {

  module.initialize_faq = function() {
    // calculate the size of the videos
    var video_classes = getVideosOnPage('faq_video_');
    size_video(video_classes);

    // resize video width if window is resized
    $(window).resize(function(){
      var video_classes = getVideosOnPage('faq_video_');
      size_video(video_classes);
    });


    $('.question').each(function(index, value){
      $(value).on('vclick', function(){
        $('#answer' + (index+1)).toggle();
      });
    });

    $('.open_close').on('click', function(){
      if($('.open_close').html() === gon.show_all){
        $('.open_close').html(gon.hide_all);
        $('.answer').show();
      }else{
        $('.open_close').html(gon.show_all);
        $('.answer').hide();
      }
    });
  };

  module.initialize_pool_tool_help = function() {
    var max_cat_loops = 5;
    var max_topic_loops = 30;

    for(var c=1; c<=max_cat_loops; c++){
      if ($('#pool_tool_help_cat'+ c).length){
        for(var t=1; t<=max_topic_loops; t++){
          if ($('#cat'+ c +'_topic'+ t +'_wrapper').length){

            // ATTENTION: Function in a loop. Do not use a reference from the outside
            // within that loop
            /*jshint -W083 */
            $('#cat'+ c +'_topic'+ t +'_wrapper').on('click', function(ev){
              // Get category and topic
              var id = ev.currentTarget.id;
              var category = id.substr(3,1);
              var topic = id.substr(10,1);

              // Remove 'selected' class from all topic elements
              for(var cc=1; cc<=max_cat_loops; cc++){
                if ($('#pool_tool_help_cat'+ cc).length){
                  $('#pool_tool_help_cat'+ cc +'_detailed_desc').hide();
                  for(var tt=1; tt<=max_topic_loops; tt++){
                    if ($('#cat'+ cc +'_topic'+ tt +'_wrapper').length){
                      $('#cat'+ cc +'_topic'+ tt +'_wrapper').removeClass('pool_tool_help_topic_wrapper_selected');
                    }
                  }
                }
              }

              // Get currently selected category and topic
              var url = window.location.href;
              var splitted_url = url.split('#');
              if(splitted_url[1] !== undefined && splitted_url[1] !== ""){
                var splitted_params = splitted_url[1].split('_');
                var category_old = parseInt(splitted_params[0].substr(9,1));
                var topic_old = parseInt(splitted_params[1].substr(6,1));

                // If new selected === current selected...close topic
                if (category === category_old.toString() && topic === topic_old.toString()){
                  window.open("#","_self");
                }else{
                  // Change link, so that we can refer from somewhere else to this link
                  window.open("#category="+ category + "_topic="+ topic,"_self");
                  setSelectedTopic(category,topic);
                }
              }else{
                // Change link, so that we can refer from somewhere else to this link
                window.open("#category="+ category + "_topic="+ topic,"_self");
                setSelectedTopic(category,topic);
              }
            });
          }else{
            break;
          }
        }
      }
      else{
        break;
      }
    }

    // calculate the size of the videos
    var video_classes = getVideosOnPage('help_video_');
    size_video(video_classes);

    // resize video width if window is resized
    $(window).resize(function(){
      var video_classes = getVideosOnPage('help_video_');
      size_video(video_classes);
    });
  };


  function getVideosOnPage(class_prefix){
    var max_videos = 20;
    var video_classes = [];

    for(var i=0; i<max_videos; i++){
      if($('.' + class_prefix + i).length){
        video_classes.push(class_prefix + i);
      }
    }

    return video_classes;
  }


  function setSelectedTopic(category, topic){
    var max_cat_loops = 5;
    var max_topic_loops = 30;

    // Add 'selecte' class to selected topic, copy detailed description
    // from hidden element to detailed description div of category &
    // show the detailed description div of the category.
    $('#cat'+ category +'_topic'+ topic +'_wrapper').addClass('pool_tool_help_topic_wrapper_selected');
    $('#pool_tool_help_cat'+ category +'_detailed_desc').html($('#cat'+ category +'_topic'+ topic +'_details').html());
    $('#pool_tool_help_cat'+ category +'_detailed_desc').fadeIn();
  }


  function setTopicOnLoad(){
    var url = window.location.href;
    var splitted_url = url.split('#');

    // If a topic and url are choosen
    if(splitted_url[1] !== undefined && splitted_url[1] !== ""){
      var splitted_params = splitted_url[1].split('_');
      var category = parseInt(splitted_params[0].substr(9,1));
      var topic = parseInt(splitted_params[1].substr(6,1));

      setSelectedTopic(category, topic);
    }
  }

  setTopicOnLoad();

})(window.ST);
