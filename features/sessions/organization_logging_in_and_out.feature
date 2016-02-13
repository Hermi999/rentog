Feature: Organization logging in and out
  In order to log in and out of Rentog
  As a Organization
  I want to be able to enter username and password and log in to Rentog and also log out

  Background:
    Given there are following users:
      | person            | organization_name |
      | kassi_testperson1 | Bosch             |
      | kassi_testperson2 | Siemens           |

  Scenario: organization logging in successfully
    Given I am not logged in
    And I am on the login page
    When I fill in "main_person_login" with "kassi_testperson1"
    And I fill in "main_person_password" with "testi"
    And I click "#main_log_in_button"
    Then I should see "Welcome, Bosch!"
    Then I should be logged in

  Scenario: organization trying to log in with false credentials
    Given I am not logged in
    And I am on the login page
    When I fill in "main_person_login" with "whatever"
    And I fill in "main_person_password" with "certainly_not_the_correct_password"
    And I click "#main_log_in_button"
    Then I should see "Sign in failed."
    Then I should not be logged in

  Scenario: organization logging out
    Given I am logged in
    When I log out
    Then I should not be logged in

  Scenario: Organization seeing its organization name on header after login
    Given I am logged in as organization "Bosch"
    And my organization name is "Bosch"
    When I am on the marketplace page
    Then I should see "Bosch"

  Scenario: Organization logs in with his primary email
    Given I am not logged in
    And I am on the login page
    When I fill in "main_person_login" with "kassi_testperson1@example.com"
    And I fill in "main_person_password" with "testi"
    And I click "#main_log_in_button"
    Then I should see "Welcome, Bosch!"
    Then I should be logged in


  Scenario: Organization logs in with his additional email
    Given user "kassi_testperson1" has additional email "work.email@example.com"
    And I am not logged in
    And I am on the login page
    When I fill in "main_person_login" with "work.email@example.com"
    And I fill in "main_person_password" with "testi"
    And I click "#main_log_in_button"
    Then I should see "Welcome, Bosch!"
    Then I should be logged in
