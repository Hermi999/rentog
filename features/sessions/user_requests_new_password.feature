Feature: User requests new password
  In order to retrieve a new password
  As a user who has forgotten his password
  I want to request a new password

  Background:
    Given community and its users are not organizations-only

  @javascript
  Scenario: User requests new password successfully
    Given I am on the marketplace page
    When I follow log in link
    And I follow "Forgot username or password"
    And I fill in "Email" with "kassi_testperson2@example.com"
    And I press "Request new password"
    Then I should see "Instructions to change your password were sent to your email." within ".flash-notifications"
    And "kassi_testperson2@example.com" should receive an email with subject "Reset password instructions"

  @javascript
  Scenario: User requests new password with email that doesnt exist
    Given I am on the marketplace page
    When I follow log in link
    And I follow "Forgot username or password"
    And I fill in "Email" with "some random string"
    And I press "Request new password"
    Then I should see "The email you gave was not found from Rentog database." within ".flash-notifications"








