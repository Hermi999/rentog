/* Tell jshint that there exists a global called gon */
/* globals console */
/* jshint unused: false */

window.ST = window.ST || {};

window.ST.trusted_relationship = (function() {
  function init(){
    disableRadioElements();

    $('.radio_trust_level').change(function(ev){
      disableRadioElements();
    });
  }

  function disableRadioElements(){
    var clicked_element = $('.radio_trust_level').filter(':checked').val();

    if (clicked_element === "trust_only_admin" ||
        clicked_element === "trust_admin_and_employees"){
      $('#shipment_no').prop('checked', true);
      $('#payment_no').prop('checked', true);
      $('.radio_shipment_necessary').attr("disabled", true);
      $('.radio_payment_necessary').attr("disabled", true);
      $('#shipment_necessary_group').css("color", "grey");
      $('#payment_necessary_group').css("color", "grey");
    }
    else{
      $('.radio_shipment_necessary').attr("disabled", false);
      $('.radio_payment_necessary').attr("disabled", false);
      $('#shipment_necessary_group').css("color", "black");
      $('#payment_necessary_group').css("color", "black");
    }
  };

  return {init: init};
})();
