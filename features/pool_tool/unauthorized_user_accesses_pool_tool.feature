@javascript
Feature: Unauthorized user tries to access the pool tool
  In order to view or edit the Pool Tool
  a person has to be logged in and authorized

  Background:
    Given there are following users:
      | person               | organization_name |
      | kassi_testperson1    | Bosch             |
      | kassi_testperson2    | Siemens           |
      | employee_testperson1 |                   |
      | employee_testperson2 |                   |
    And there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" and with listing shape "Renting"
    And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" and with listing shape "Renting"

  Scenario: Access any companies Pool Tool without logging in
    Given I am not logged in
    And I am on the home page
    When I go to the pool tool page of "kassi_testperson1"
    Then I should be on the home page
    And I should see "You must be a company member"

  Scenario: Access another companies Pool Tool as employee
    Given I am logged in as "employee_testperson2"
    And I am on the home page
    When I go to the pool tool page of "kassi_testperson1"
    Then I should be on the home page
    And I should see "You must be a company member"

  Scenario: Access another companies Pool Tool as company admin
    Given I am logged in as "kassi_testperson2"
    And I am on the home page
    When I go to the pool tool page of "kassi_testperson1"
    Then I should be on the home page
    And I should see "You must be a company member"
