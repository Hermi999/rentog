/* Tell jshint that there exists a global called gon */
/* globals gon, getUrlParameter, console */
/* jshint unused: false, $ */

window.ST = window.ST || {};

window.ST.importexport = (function(module) {
  function init(){
    module.set_datepicker_language(gon);
    module.initialize_datepicker("#datepicker", '#start-on', '#end-on', 'date-start-output', 'date-end-output');


    $('#export-button').click(function(ev){
      var params = "";
      if ($('#date-start-output').val() !== "" && $('#date-end-output').val() !== ""){
        params = "?start_on=" + $('#date-start-output').val() + "&end_on=" + $('#date-end-output').val();
      }
      window.location.href = "/" + gon.locale + "/export" + params;
    });
  }

  return {
    init: init
  };
})(window.ST);

