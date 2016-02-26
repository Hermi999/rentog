window.ST.onFollowButtonAjaxComplete = function(event, xhr) {
  var target = $(event.target);
  var newButtonContainer = $(xhr.responseText);

  // Work around "Unfollow" showing up too soon
  $(".button-hoverable", newButtonContainer).addClass("button-disable-hover");
  newButtonContainer.on(
    "mouseleave", function() {
      $(".button-disable-hover", newButtonContainer).removeClass("button-disable-hover");
    }
  );

  target.parents(".follow-button-container:first").replaceWith(newButtonContainer);
  $(".follow-button", newButtonContainer).on("ajax:complete", window.ST.onFollowButtonAjaxComplete);
  $(".follow-button-small", newButtonContainer).on("ajax:complete", window.ST.onFollowButtonAjaxComplete);
};


// After klicked on trust button
window.ST.onTrustButtonAjaxComplete = function(event, xhr) {
  var target = $(event.target);
  var newButtonContainer = $(xhr.responseText);

  // Work around "Unfollow" showing up too soon
  $(".button-hoverable", newButtonContainer).addClass("button-disable-hover");
  newButtonContainer.on(
    "mouseleave", function() {
      $(".button-disable-hover", newButtonContainer).removeClass("button-disable-hover");
    }
  );

  target.parents(".trust-button-container:first").replaceWith(newButtonContainer);
  $(".trust-button", newButtonContainer).on("ajax:complete", window.ST.onTrustButtonAjaxComplete);

};



window.ST.onEmployeeButtonAjaxComplete = function(event, xhr) {
  var target = $(event.target);
  var newButtonContainer = $(xhr.responseText);

  // Work around "Unfollow" showing up too soon
  $(".button-hoverable", newButtonContainer).addClass("button-disable-hover");
  newButtonContainer.on(
    "mouseleave", function() {
      $(".button-disable-hover", newButtonContainer).removeClass("button-disable-hover");
    }
  );

  target.parents(".employ-button-container:first").replaceWith(newButtonContainer);
  $(".employ-button", newButtonContainer).on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);
  $(".employ-button-new", newButtonContainer).on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);
  $(".employ-button-small", newButtonContainer).on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);
  $(".employ-button-small-new", newButtonContainer).on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);
};



window.ST.initializeFollowButtons = function() {
  $('.hover-content').click(function(ev){
    var r = confirm(window.ST.untrust_warning);

    if(!r){
      ev.stopImmediatePropagation();
      ev.preventDefault();
    }
  });

  $(".follow-button").on("ajax:complete", window.ST.onFollowButtonAjaxComplete);
  $(".follow-button-small").on("ajax:complete", window.ST.onFollowButtonAjaxComplete);
  $(".trust-button").on("ajax:complete", window.ST.onTrustButtonAjaxComplete);
  $(".employ-button").on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);
  $(".employ-button-new").on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);
  $(".employ-button-small").on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);
  $(".employ-button-small-new").on("ajax:complete", window.ST.onEmployeeButtonAjaxComplete);

};
