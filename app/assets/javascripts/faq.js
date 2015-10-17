window.ST = window.ST || {};

(function(module) {

  module.initialize_faq = function() {
    $('.question').each(function(index, value){
      $(value).on('vclick', function(){
        // hideAll();
        $('#answer' + (index+1)).toggle();
      });
    });
  };

  var hideAll = function(){
    $('.answer').hide();
  };

})(window.ST);
