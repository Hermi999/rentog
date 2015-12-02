// This file provides basic MIXPANEL tracking functions
// This file also assigns tracking to a viarity of page visit events
//
// Clicks on forms are validated with jquery validate. Therefore the
// calls to the tracking API are placed within the submit handler of the
// validate() function (most times within kassi.js).


// Track only in production - we do not want to falsify our data with development data
var track = function(){
  if(typeof mixpanel !== 'undefined'){
    return true;
  }else{
    return false;
  }
};

// Get URL query string params, so that we can create events for various campaigns
var getTrackingURLParameters = function (){
  var trackingKeys = ['utm_campaign',
                      'utm_medium',
                      'utm_source',
                      'utm_term',
                      'utm_content',
                      'campaign_id',
                      'email'];
  var trackingParams = {
    obj: {},
    str: ""
  };

  for (var i=0; i<trackingKeys.length; i++){
    var val = getUrlParameter(trackingKeys[i]);

    if (val !== undefined){
      trackingParams.obj[trackingKeys[i]] = val;

      if (trackingParams.str !== ""){
        trackingParams.str = trackingParams.str + "&" + trackingKeys[i] + "=" + val;
      }else{
        trackingParams.str = trackingKeys[i] + "=" + val;
      }
    }
  }

  return trackingParams;
}

// Get url parameters for tracking
var trackingParams = getTrackingURLParameters();


// Handle the various pages
  if (track()){

    // Landing page
    if (window.location.pathname === "/landingpage"){
      // Tracking email campaigns
      if (trackingParams.obj.utm_medium === "email"){
          mixpanel.register_once(trackingParams.obj);
          mixpanel.track("Email campaign visitor");
      }

      // Get Android App
      $('.landingpage-android-store-icon').on('click', function(){
        mixpanel.track("Landingpage: Get Android App");
      });

      // How it works button clicked
      $("#scrollToVideo").click(function(ev) {
        mixpanel.track("Landingpage: How it works Button clicked");
      });
    }


    // Signup page
    if (window.location.pathname.match(/\.*(\/signup)\$/i)){
      mixpanel.track("Signup page visited");


    }


    // Invite page
    if (window.location.pathname.match(/\.*(\/invitations\/new)\$/i)){
      // mixpanel.track("Invite page visited");

    }
  }

