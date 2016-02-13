@javascript
Feature: User tries to access the pool tool
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

  Scenario: Access own Pool Tool as company admin
    Given I am logged in as "kassi_testperson1"
    And I am on the marketplace page
    When I click "#header-user-display-name"
    When I follow "Pool Tool"
    Then I should see "Pool Management Tool"
    And I should see "Add new booking"
    And I should see "Post a new listing"
    And I should see "Listing1"
    And I should see "Listing2"

  Scenario: Access own companies Pool Tool as employee
    Given I am logged in as "kassi_testperson1"
    And I am on the marketplace page
    When I click "#header-user-display-name"
    When I follow "Pool Tool"
    Then I should see "Pool Management Tool"
    And I should see "Listing1"
    And I should see "Listing2"

  Scenario: Access own companies Pool Tool without open listings
    Given I am logged in as "kassi_testperson2"
    And I am on the marketplace page
    When I click "#header-user-display-name"
    When I follow "Pool Tool"
    Then I should see "Pool Management Tool"
    And I should see "Your company has no (open) devices yet"
    And I should see "create a new listing here"
    When I follow "here" within "#create_new_listing"
    Then I should see "Post a new listing"

  Scenario: Access any Pool Tool as Rentog admin
    Given I am logged in as "kassi_testperson2"
    And "kassi_testperson2" has admin rights in community "test"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson1"
    Then I should see "Pool Management Tool"
    And I should see "Add new booking"
    And I should see "Post a new listing"
    And I should see "Listing1"
    And I should see "Listing2"

  Scenario: Access any companies Pool Tool without logging in
    Given I am not logged in
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson1"
    Then I should be on the marketplace page
    And I should see "You must be a company member"

  Scenario: Access another companies Pool Tool as employee
    Given I am logged in as "employee_testperson2"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson1"
    Then I should be on the marketplace page
    And I should see "You must be a company member"

  Scenario: Access another companies Pool Tool as company admin
    Given I am logged in as "kassi_testperson2"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson1"
    Then I should be on the marketplace page
    And I should see "You must be a company member"
