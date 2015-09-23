@javascript
Feature: Company verifies employee
  A company has to verify its employees. Otherwise their profiles are locked

  Background:
    Given there are following users:
      | person     | given_name | family_name | organization_name | email                | is_organization | company  |
      | company_1  | comp1      | any1        | Company1          | comp1@example.com    | 1               |          |
      | company_2  | comp2      | any2        | Company1          | comp2@example.com    | 1               |          |
      | employee_1 | empl1      | oyee1       |                   | empl1@example.com    | 0               | Company1 |
      | employee_2 | empl2      | oyee2       |                   | empl2@example.com    | 0               | Company2 |
    And I am logged in as "company_1"
    And I am on my profile page


  Scenario: Company verifies and removes employee
    Then I should see "Company1"
    And I should see "empl1"
    And I should see "Accept"

    # Verify employee
    When I follow "Accept"
    And I wait for 1 seconds
    Then I should see "Employee"

    # Check if employees profile isn't locked
    Given I am logged in as "employee_1"
    Then I should not see "Your company administrator needs to verify you"

    # Remove employee
    Given I am logged in as "company_1"
    And I am on the profile page of "company_1"
    #When I hover ".employ-button-small"
    #Then I should see "Remove"
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
    When I remove employee
    Then I should see "Accept"

    # Check if employees profile is locked
    Given I am logged in as "employee_1"
    Then I should see "You have to be verified by your company admin."
    And I go to the home page
    Then I should see "Your company administrator needs to verify you"
