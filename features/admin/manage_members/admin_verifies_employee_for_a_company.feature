@javascript
Feature: Admin verifies employee for a company
  The administrator can list all the employees of a certain company on the
  companies profile page.
  He can also verify an employee for a company, so that the employee account
  is active.

  Background:
    Given there are following users:
      | person     | given_name | family_name | organization_name | email                | is_organization | company  |
      | company_1  | comp1      | any1        | Company1          | comp1@example.com    | 1               |          |
      | company_2  | comp2      | any2        | Company1          | comp2@example.com    | 1               |          |
      | employee_1 | empl1      | oyee1       |                   | empl1@example.com    | 0               | Company1 |
      | employee_2 | empl2      | oyee2       |                   | empl2@example.com    | 0               | Company2 |
      | admin_1    | admin      | istrator    | Admin             | admin@example.com    | 1               |          |
    And "admin_1" has admin rights in community "test"
    And I am logged in as "admin_1"
    And I am on the profile page of "company_1"

  Scenario: Admin verifies and removes employee for a company
    Then I should see "Company1"
    And I should see "empl1"
    And I should see "Accept"

    When I follow "Accept"
    And I wait for 1 seconds
    Then I should see "Employee"

    Given I am logged in as "employee_1"
    Then I should not see "Your company administrator needs to verify you"

    Given I am logged in as "admin_1"
    And I am on the profile page of "company_1"
    #When I hover ".employ-button-small"
    #Then I should see "Remove"
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
    When I remove employee
    Then I should see "Accept"

    Given I am logged in as "employee_1"
    Then I should see "You have to be verified by your company admin."
    And I go to the marketplace page
    Then I should see "Your company administrator needs to verify you"
