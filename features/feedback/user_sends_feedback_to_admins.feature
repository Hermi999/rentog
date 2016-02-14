# wah: Handled with wordpress, commented out the Sharetribe functionality

 Feature: User sends feedback to admins
   In order to uggest a new feature, report a bug, or tell my opinion about Rentog
   As a user of Rentog
   I want to be able to give feedback to Rentog administrators

  @javascript
  Scenario: Giving feedback successfully
    Given I am on the marketplace page
    When I follow "Contact" within the footer
    Then I should see "Contact us | Send us your feedback" within "#contact_us_btn"

#   @javascript
#   Scenario: Giving feedback successfully when not logged in
#     Given I am on the marketplace page
#     When I follow "Contact" within the footer
#     And I fill in "Your email address" with "test@example.com"
#     And I fill in "What would you like to tell us?" with "Feedback"
#     And I press "Send feedback"
#     Then I should see "Thanks a lot for your feedback!" within ".flash-notifications"

#   @javascript
#   Scenario: Giving feedback successfully when logged in
#     Given I am logged in
#     When I follow "Contact" within the footer
#     Then I should not see "Your email"
#     When I fill in "What would you like to tell us?" with "Feedback"
#     And I press "Send feedback"
#     Then I should see "Thanks a lot for your feedback!"

#   @javascript
#   Scenario: Trying to give invalid feedback
#     Given I am on the marketplace page
#     When I follow "Contact" within the footer
#     And I fill in "Your email address" with "test"
#     And I press "Send feedback"
#     Then I should see "This field is required"
#     And I should see "Please enter a valid email address"

#   @javascript
#   Scenario: Trying to send a spam link
#     Given I am logged in
#     When I follow "Contact" within the footer
#     And I fill in "What would you like to tell us?" with "[url=testi"
#     And I press "Send feedback"
#     Then I should see "Feedback not saved, due to its formatting. Try again or use the feedback forum." within ".flash-notifications"
#     When I fill in "What would you like to tell us?" with "<a href="
#     And I press "Send feedback"
#     Then I should see "Feedback not saved, due to its formatting. Try again or use the feedback forum."



