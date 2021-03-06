/* Tell jshint that there exists a global called "gon" */
/* globals gon */
/* jshint unused: false */

window.ST = window.ST || {};


window.ST.invitations = function() {

  function init(){
    $('#invitation_target_employee').on('change', function(ev){
      var current_text = $('#invitation_message').val();
      var original_text3 = gon.invitation_message_field_placeholder3;
      var original_text2 = gon.invitation_message_field_placeholder2;
      var original_text1 = gon.invitation_message_field_placeholder1;

      if (current_text === original_text2 || current_text === original_text3){
        $('#invitation_message').val(original_text1);
      }
    });

    $('#invitation_target_shared_pool').on('change', function(ev){
      var current_text = $('#invitation_message').val();
      var original_text3 = gon.invitation_message_field_placeholder3;
      var original_text2 = gon.invitation_message_field_placeholder2;
      var original_text1 = gon.invitation_message_field_placeholder1;

      if (current_text === original_text1 || current_text === original_text3){
        $('#invitation_message').val(original_text2);
      }
    });

    $('#invitation_target_any').on('change', function(ev){
      var current_text = $('#invitation_message').val();
      var original_text3 = gon.invitation_message_field_placeholder3;
      var original_text2 = gon.invitation_message_field_placeholder2;
      var original_text1 = gon.invitation_message_field_placeholder1;

      if (current_text === original_text1 || current_text === original_text2){
        $('#invitation_message').val(original_text3);
      }
    });

    $('#target_employee_label').on('click', function(){
      $('#invitation_target_employee').prop("checked", true);
      $('#invitation_target_employee').change();
    });

    $('#target_any_label').on('click', function(){
      $('#invitation_target_any').prop("checked", true);
      $('#invitation_target_any').change();
    });

    $('#target_shared_pool_label').on('click', function(){
      $('#invitation_target_shared_pool').prop("checked", true);
      $('#invitation_target_shared_pool').change();
    });
  }

  return {
    init: init,
  };
};
