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
    // Logout
    mixpanel.track_links("#signoutlink", "Logout");

    /*
    // Navigation bar click
    mixpanel.track_links("#header-user-toggle-menu a", "Click on Navigation Link", {
      // object
    });
    */


    // Landing page
    if (window.location.pathname === "/landingpage"){
      // Tracking email campaigns
      if (trackingParams.obj.utm_medium === "email"){
          mixpanel.register(trackingParams.obj);
          mixpanel.track("Email campaign visitor");
      }

      // Get Android App
      $('.landingpage-android-store-icon').on('click', function(){
        mixpanel.track("Landingpage: Get Android App");
      });
    }


    // Signup page
    if (window.location.pathname.match(/\.*(\/signup)$/i)){
      mixpanel.track("Signup page visited");
    }


    // PoolTool page
    if (window.location.pathname.match(/\.*(\/poolTool)$/i)){
      // On login
      if(document.referrer.match(/\.*(\/login)$/i) ||
         document.referrer.match(/\.*(\/sessions)$/i)){
        mixpanel.identify(gon.current_user_email);
        mixpanel.track("Signin");

        // Now remove referrer (because of site reload --> same referrer)
        var meta = document.createElement('meta');
        meta.name = "referrer";
        meta.content = "no-referrer";
        document.getElementsByTagName('head')[0].appendChild(meta);
      }
    }


    // Invite page
    if (window.location.pathname.match(/\.*(\/invitations\/new)$/i)){
      // mixpanel.track("Invite page visited");

    }

    // New Listing page
    if (window.location.pathname.match(/\.*(\/listings\/new)$/i)){
      // do nothing
    }
  }

