@javascript
Feature: User deletes an existing booking in pool tool
  As a company admin I want to create, update and delete Bookings within
  the Pool Tool

  Background:
    Given there are following users:
      | person               | organization_name |
      | kassi_testperson1    | Bosch             |
      | kassi_testperson2    | Siemens           |
      | employee_testperson1 |                   |
      | employee_testperson2 |                   |

  @skip_phantomjs
  Scenario: Delete existing Booking with Employee
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
      And there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an internal booking for company "kassi_testperson2" and employee "employee_testperson2" and listing "Listing1" with length 2 and offset 1 days
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "Testperson5 Hermann" within ".poolTool_gantt_container"
     When I click on element "div" with text "Testperson5 Hermann" and within ".gantt_ownEmployee"
     Then I should see element "#cboxLoadedContent"
     When I click element "#btn_delete"
      And I confirm alert popup
      And I wait for 1 seconds
     Then I should not see element "#error_message"
      And I should not see "Testperson5 Hermann" within ".poolTool_gantt_container"
      And there should not be a booking with starter "employee_testperson2" in the Db
    # done

  @skip_phantomjs
  Scenario: Delete existing Booking with other Reason
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
      And there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an internal booking for company "kassi_testperson2" and listing "Listing1" with reason "internal000" and length 2 days and offset 1 days
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason_me"
     Then I should see element "#cboxLoadedContent"
     When I click element "#btn_delete"
      And I confirm alert popup
      And I wait for 1 seconds
     Then I should not see element "#error_message"
      And I should not see "internal000" within ".poolTool_gantt_container"
      And there should not be a booking with starter "kassi_testperson2" and reason "internal000" in the Db
    # done
