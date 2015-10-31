window.ST = window.ST || {};

(function(module) {

  module.initialize_faq = function() {
    $('.question').each(function(index, value){
      $(value).on('vclick', function(){
        $('#answer' + (index+1)).toggle();
      });
    });
  };

})(window.ST);
