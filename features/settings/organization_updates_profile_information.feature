Feature: Organization updates profile information
  In order to change the information the other organizations see in my profile page
  As an organization
  I want to able to update my profile information

  Background:
    Given there are following users:
      | person            | organization_name |
      | kassi_testperson2 | Hofer             |
    And I am logged in as "kassi_testperson2"
    And I am on the profile settings page

  @javascript
  Scenario: Updating profile successfully
    When I fill in "Organization name" with "Test"
    And I fill in "Location" with "Broadway"
    And wait for 2 seconds
    And I fill in "Phone number" with "0700-715517"
    And I fill in "About you" with "Some random text about me"
    And I press "Save information"
    Then I should see "Information updated" within ".flash-notifications"
    And the "Organization name" field should contain "Test"
    And the "Location" field should contain "Broadway"
    And I should not see my username

  # Update of profile avatar is checked in file "user_updates_profile_information.feature"
