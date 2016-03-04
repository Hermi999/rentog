@javascript
Feature: User views empty Pool Tool
  If a user visits the pool tool and there are no open renting devices,
  show an overlay with a messege.

  Background:
    Given there are following users:
      | person               | organization_name |
      | kassi_testperson1    | Bosch             |
      | kassi_testperson2    | Siemens           |
      | employee_testperson1 |                   |
      | employee_testperson2 |                   |


  Scenario: Initial Pool Tool Access
    Given I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "Your company has no (open) devices for renting yet"
      And I should see "create a new renting listing here"
     When I follow "here" within "#create_new_listing"
     Then I should see "Post a new listing"

    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
    Given there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "trusted" and with listing shape "Private devices"
    Given there is a listing with title "Listing3" from "kassi_testperson2" with category "Tools" and with listing shape "Renting"
      And I am on my pool tool page
     Then I should see "Pool Management Tool"
      And I should not see element "#addNewBookingForm"
      And I should see "Listing1"
      And I should see "intern"
      And I should see "Listing2"
      And I should see "Trusted"
      And I should see "Listing3"
      And I should see "All"
    #done

  Scenario: Pool Tool without renting listings
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Selling"
    Given there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "trusted" and with listing shape "Requesting"
    Given I am logged in as "kassi_testperson2"

      And I am on my pool tool page
     Then I should see "Pool Management Tool"
     Then I should see "Your company has no (open) devices for renting yet"
      And I should see "create a new renting listing here"
     When I follow "here" within "#create_new_listing"
     Then I should see "Post a new listing"
    #done
