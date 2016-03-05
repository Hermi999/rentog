@javascript
Feature: User tries to view the pool tool
  In order to view or edit the Pool Tool
  a person has to be logged in and authorized
  and either to be a company member or a member
  of a trusted company.

  Background:
    Given there are following users:
      | person               | organization_name |
      | kassi_testperson1    | Bosch             |
      | kassi_testperson2    | Siemens           |
      | kassi_testperson3    | Continental       |
      | employee_testperson1 | " "               |
      | employee_testperson2 | " "               |
      | employee_testperson3 | " "               |
    And there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" and with listing shape "Renting"
    And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" and with listing shape "Renting"

    And there is a listing with title "Listing_intern" from "kassi_testperson3" with category "Tools" with availability "intern" and with listing shape "Private devices"
    And there is a listing with title "Listing_trusted" from "kassi_testperson3" with category "Tools" with availability "trusted" and with listing shape "Private devices"
    And there is a listing with title "Listing_all" from "kassi_testperson3" with category "Tools" and with listing shape "Renting"
    And there exists an internal booking for company "kassi_testperson3" and employee "employee_testperson3" and listing "Listing_intern" with length 2 and offset 1 days
    And there exists an internal booking for company "kassi_testperson3" and employee "employee_testperson3" and listing "Listing_all" with length 4 and offset 3 days
    And there exists an internal booking for company "kassi_testperson3" and employee "employee_testperson3" and listing "Listing_trusted" with length 6 and offset 3 days


  Scenario: Access own Pool Tool as company admin
    Given I am logged in as "kassi_testperson2"
    And I am on the marketplace page
    When I click "#header-user-display-name"
    When I follow "Pool Tool"
    Then I should see "Pool Management Tool"
    And I should see "Book internal device"
    And I should see "Post a new listing"
    And I should see "Listing1"
    And I should see "Listing2"

  Scenario: Access own companies Pool Tool as employee
    Given I am logged in as "kassi_testperson2"
    And I am on the marketplace page
    When I click "#header-user-display-name"
    When I follow "Pool Tool"
    Then I should see "Pool Management Tool"
    And I should see "Listing1"
    And I should see "Listing2"

  Scenario: Access own companies Pool Tool without open listings
    Given I am logged in as "kassi_testperson1"
    And I am on the marketplace page
    When I click "#header-user-display-name"
    When I follow "Pool Tool"
    Then I should see "Pool Management Tool"
    And I should see "Your company has no (open) devices for renting yet"
    And I should see "create a new renting listing here"
    When I follow "here" within "#create_new_listing"
    Then I should see "Post a new listing"

  Scenario: Access any Pool Tool as Rentog admin
    Given I am logged in as "kassi_testperson3"
    And "kassi_testperson3" has admin rights in community "test"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson2"
    Then I should see "Pool Management Tool"
    And I should see "Book internal device"
    And I should see "Post a new listing"
    And I should see "Listing1"
    And I should see "Listing2"

  Scenario: Access other companies Pool Tool as trusted company
    Given "kassi_testperson3" follows "kassi_testperson2"
    And I am logged in as "kassi_testperson2"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson3"
    Then I should see "Continental's device pool"
    And I should see "Listing_trusted"
    And I should see "Listing_all"
    And I should not see "Listing_intern"
    And I should not see "Testperson4 Hermann"

  Scenario: Access other companies Pool Tool as trusted employee
    Given "kassi_testperson3" follows "kassi_testperson2"
    And I am logged in as "employee_testperson2"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson3"
    Then I should see "Continental's device pool"
    And I should see "Listing_trusted"
    And I should see "Listing_all"
    And I should not see "Listing_intern"
    And I should not see "Testperson4 Hermann"

  Scenario: Can not access any companies Pool Tool without logging in
    Given I am not logged in
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson2"
    Then I should be on the login page
    And I should see "You must be a company member"

  Scenario: Can not access another companies Pool Tool as untrusted employee
    Given I am logged in as "employee_testperson3"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson2"
    Then I should be on my companies pool tool page
    And I should see "You must be a company member"

  Scenario: Can not access another companies Pool Tool as untrusted company admin
    Given I am logged in as "kassi_testperson3"
    And I am on the marketplace page
    When I go to the pool tool page of "kassi_testperson2"
    Then I should be on my pool tool page
    And I should see "You must be a company member"
