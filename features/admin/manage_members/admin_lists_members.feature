@javascript
Feature: Admin lists members
  The administrator can list all the users (companies & employees).
  He can also order the list by name, email, joined date & orga.
  If he orders by Name, then @ first the users will be ordered by the orga_name
  and then by the first name.

  Background:
    Given there are following users:
      | person               | given_name | family_name | organization_name | email                | is_organization | membership_created_at     |
      | manager              | matti      | manager     | Samsung           | manager@example.com  | 1               | 2014-03-01 00:12:35 +0000 |
      | kassi_testperson1    | john       | doe         | Siemens           | test2@example.com    | 1               | 2013-03-01 00:12:35 +0000 |
      | kassi_testperson2    | jane       | doe         | " "               | test1@example.com    | 0               | 2012-03-01 00:00:00 +0000 |
      | employee_testperson1 | xxxx       | yyy         | " "               | test0@example.com    | 0               | 2011-03-01 00:00:00 +0000 |
      | employee_testperson2 | vvvv       | www         | " "               | test3@example.com    | 0               | 2010-03-01 00:00:00 +0000 |
    And I am logged in as "manager"
    And "manager" has admin rights in community "test"
    And "kassi_testperson1" has admin rights in community "test"
    And I am on the manage members admin page

# wah: Not an essential test. Skip this one
  # Scenario: Admin views & sorts list of members
  #   Then I should see list of users with the following details:
  #     | Name          | Email               | Joined     | Admin | Remove User |
  #     | Samsung       | manager@example.com | Mar 1, 2014 |       |             |
  #     | Siemens       | test2@example.com   | Mar 1, 2013 |       |             |
  #     | jane doe      | test1@example.com   | Mar 1, 2012 |       |             |
  #     | xxxx yyy      | test0@example.com   | Mar 1, 2011 |       |             |
  #     | vvvv www      | test3@example.com   | Mar 1, 2010 |       |             |
  #   When I click on element "div" with text "Name" and within ".sort-text-wrapper"
  #   Then I should see list of users with the following details:
  #     | Name          | Email               | Joined     | Admin | Remove User |
  #     | jane doe      | test1@example.com   | Mar 1, 2012 |       |             |
  #     | vvvv www      | test3@example.com   | Mar 1, 2010 |       |             |
  #     | xxxx yyy      | test0@example.com   | Mar 1, 2011 |       |             |
  #     | Samsung       | manager@example.com | Mar 1, 2014 |       |             |
  #     | Siemens       | test2@example.com   | Mar 1, 2013 |       |             |
  #   When I click on element "div" with text "Name" and within ".sort-text-wrapper"
  #   Then I should see list of users with the following details:
  #     | Name          | Email               | Joined     | Admin | Remove User |
  #     | Siemens       | test2@example.com   | Mar 1, 2013 |       |             |
  #     | Samsung       | manager@example.com | Mar 1, 2014 |       |             |
  #     | xxxx yyy      | test0@example.com   | Mar 1, 2011 |       |             |
  #     | vvvv www      | test3@example.com   | Mar 1, 2010 |       |             |
  #     | jane doe      | test1@example.com   | Mar 1, 2012 |       |             |
  #   When I follow "Email"
  #   Then I should see list of users with the following details:
  #     | Name          | Email               | Joined     | Admin | Remove User |
  #     | Samsung       | manager@example.com | Mar 1, 2014 |       |             |
  #     | xxxx yyy      | test0@example.com   | Mar 1, 2011 |       |             |
  #     | jane doe      | test1@example.com   | Mar 1, 2012 |       |             |
  #     | Siemens       | test2@example.com   | Mar 1, 2013 |       |             |
  #     | vvvv www      | test3@example.com   | Mar 1, 2010 |       |             |
  #   When I follow "Joined"
  #   Then I should see list of users with the following details:
  #     | Name          | Email               | Joined     | Admin | Remove User |
  #     | vvvv www      | test3@example.com   | Mar 1, 2010 |       |             |
  #     | xxxx yyy      | test0@example.com   | Mar 1, 2011 |       |             |
  #     | jane doe      | test1@example.com   | Mar 1, 2012 |       |             |
  #     | Siemens       | test2@example.com   | Mar 1, 2013 |       |             |
  #     | Samsung       | manager@example.com | Mar 1, 2014 |       |             |
  #   When I follow "Orga?"
  #   Then I should see list of users with the following details:
  #     | Name          | Email               | Joined     | Admin | Remove User |
  #     | vvvv www      | test3@example.com   | Mar 1, 2010 |       |             |
  #     | xxxx yyy      | test0@example.com   | Mar 1, 2011 |       |             |
  #     | jane doe      | test1@example.com   | Mar 1, 2012 |       |             |
  #     | Siemens       | test2@example.com   | Mar 1, 2013 |       |             |
  #     | Samsung       | manager@example.com | Mar 1, 2014 |       |             |
  #   When I follow "Orga?"
  #   Then I should see list of users with the following details:
  #     | Name          | Email               | Joined     | Admin | Remove User |
  #     | Samsung       | manager@example.com | Mar 1, 2014 |       |             |
  #     | Siemens       | test2@example.com   | Mar 1, 2013 |       |             |
  #     | jane doe      | test1@example.com   | Mar 1, 2012 |       |             |
  #     | xxxx yyy      | test0@example.com   | Mar 1, 2011 |       |             |
  #     | vvvv www      | test3@example.com   | Mar 1, 2010 |       |             |

  Scenario: Admin views member count
    Given there are 50 companies with organization_name prefix "Company"
    And I go to the manage members admin page
    Then I should see a range from 1 to 50 with total user count of 55

  Scenario: Admin views multiple users with pagination
    Given there are 50 companies with organization_name prefix "Company"
    And I go to the manage members admin page
    Then I should see 50 users
    And the first user should be "Company 50"
    When I follow "Next"
    Then I should see 5 users
    And the first user should be "Samsung"

  Scenario: Admin verifies sellers
    Given only verified users can post listings in this community
    And I refresh the page
    Then I should see that "Siemens" cannot post new listings
    When I verify user "Siemens" as a seller
    Then I should see that "Siemens" can post new listings
    When I refresh the page
    Then I should see that "Siemens" can post new listings

  Scenario: Admin removes a company
    Given there is a listing with title "Sledgehammer" from "kassi_testperson1" with category "Items" and with listing shape "Requesting"

     When I am on the marketplace page
     Then I should see "Sledgehammer"

    Given I am on the manage members admin page
      And I will confirm all following confirmation dialogs in this page if I am running PhantomJS
     When I remove user "Siemens"
     Then I should not see "Siemens"

      # Identifying is easier when using username
      And "kassi_testperson1" should be banned from this community

     When I am on the marketplace page
     Then I should not see "Sledgehammer"

  Scenario: Admin promotes user to admin
    Then I should see that "Samsung" has admin rights in this community
    Then I should see that "Siemens" has admin rights in this community
    Then I should see that "jane doe" does not have admin rights in this community
    When I promote "jane doe" to admin
    Then I should see that "jane doe" has admin rights in this community
    When I refresh the page
    Then I should see that "jane doe" has admin rights in this community

  Scenario: Admin is not able to remove her own admin rights
    Then I should see that "jane doe" does not have admin rights in this community
    And I should see that I can remove admin rights of "Siemens"
    Then I should see that "Samsung" has admin rights in this community
    And I should see that I can not remove admin rights of "Samsung"
