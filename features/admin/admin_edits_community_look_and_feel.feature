@javascript
Feature: Admin edits community look-and-feel
  In order to give diversify my marketplace from my competitors
  As an admin
  I want to be able to modify look-and-feel

  Background:
     Given there are following users:
      | person               | given_name | family_name | email               | organization_name | membership_created_at     | company   |
      | manager              | matti      | manager     | manager@example.com | Test_Orga         | 2014-03-01 00:12:35 +0200 |           |
      | kassi_testperson1    | john       | doe         | test2@example.com   | Test_Orga         | 2013-03-01 00:12:35 +0200 |           |
      | kassi_testperson2    | jane       | doe         | test1@example.com   | Test_Orga         | 2012-03-01 00:00:00 +0200 |           |
      | employee_testperson1 | employee   | yee         | empl1@example.com   |                   | 2015-03-01 00:00:00 +0200 | Test_Orga |
    And I am logged in as "manager"
    And "manager" has admin rights in community "test"
    And "kassi_testperson1" has admin rights in community "test"
    And "employee_testperson1" has admin rights in community "test"
    And I am on the edit look-and-feel page

  Scenario: Admin can change the default listing view to list
    Given community "test" has default browse view "grid"
    When I change the default browse view to "List"
    And I go to the homepage
    Then I should see the browse view selected as "List"

  Scenario: Admin can change the name display type of employee to full name (First Last)
    And I am logged in as "employee_testperson1"
    And I am on the edit look-and-feel page
    And community "test" has name display type "first_name_with_initial"
    When I change the name display type to "Full name (First Last)"
    And I refresh the page
    Then I should see my name displayed as "employee yee"

  Scenario: Admin changes the name display type to full name and there is no difference [organization-only Marketplace]
    Given community "test" has name display type "first_name_with_initial"
    And community "test" allows only organizations
    When I change the name display type to "Full name (First Last)"
    And I refresh the page
    Then I should see my name displayed as "Test_Orga"

  Scenario: Admin changes main color
    Then I should see that the background color of Post a new listing button is "00A26C"
    And I set the main color to "FF0099"
    And I press submit
    And I should see "Stylesheet is recompiling. Please, reload the page after a while."
    And the system processes jobs
    And I refresh the page
    Then I should see that the background color of Post a new listing button is "FF0099"

  @skip_phantomjs
  Scenario: Admin uploads a favicon
    Then I should see that the favicon is the default
    And I upload a new favicon
    And I press submit
    Then I should see that the favicon is the file I uploaded
