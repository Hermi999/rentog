$(function() {
  var toggles = [];
  var toggles_reverse = [];

  function closeAll() {
    toggles.forEach(function(toggle) {
      toggle.close();
    });

    toggles_reverse.forEach(function(toggle_reverse) {
      toggle_reverse.close();
    });
  }

  function toggleMenu(el) {
    var $menu = $(el.attr('data-toggle'));
    var anchorElement = $(el.attr('data-toggle-anchor-element') || el);
    var anchorPosition = el.attr('data-toggle-anchor-position') || "left";
    var togglePosition = el.attr('data-toggle-position') || "relative";

    function absolutePosition(reverse) {
      var anchorOffset = anchorElement.offset();
      var top = anchorOffset.top + anchorElement.outerHeight();
      var left = anchorOffset.left;

      if(anchorPosition === "right") {
        var right = left - ($menu.outerWidth() - anchorElement.outerWidth());
        $menu.css("left", right);
      } else {
        $menu.css("left", left);
      }

      if (reverse){

      }else{
        $menu.css("top", top);
      }
    }

    function open(reverse) {
      // Opens the menu toggle menu
      closeAll();

      if (togglePosition === "absolute") {
        absolutePosition(reverse);
      }

      $menu.removeClass('hidden');
      el.addClass('toggled');
      toggleFn = close;
    }

    function close() {
      // Closes the target toggle menu
      $menu.addClass('hidden');
      el.removeClass('toggled');
      toggleFn = open;
    }

    var toggleFn = open;

    el.click(function(event) {
      event.stopPropagation();

      if (event.currentTarget.className.indexOf("reverse") > 0){
        toggleFn(true);
      }
      else{
        toggleFn(false);
      }

    });

    $menu.click(function(event){
      event.stopPropagation();
    });

    return {
      close: close
    };
  }

  // Initialize menu
  toggles = _.toArray($('.toggle')).map(function(el) {
    return toggleMenu($(el));
  });

  toggles_reverse = _.toArray($('.toggle_reverse')).map(function(el) {
    return toggleMenu($(el));
  });

  // All dropdowns are collapsed when clicking outside dropdown area
  $(document).click( function(){
    closeAll();
  });
});
