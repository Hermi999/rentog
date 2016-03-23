@javascript
Feature: User performs a combination of show, create, update, delete actions on pool tool
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
  Scenario: Create, update and delete a booking in a row
    # Create
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
      And there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     When I press "Book internal device"
      And I select "Hermann Testperson5" from "dd_employee"
      And I click on element "div.fluid-thumbnail-grid-image-title" with text "Listing2" and within ".home-fluid-thumbnail-grid"
      And I fill booking start-date +2 and end-date +5 days
      And I press "Create"
     Then I should see "Testperson5 Hermann" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson2" in the Db

    # Update
     When I click on element "div" with text "Testperson5 Hermann" and within ".gantt_ownEmployee"
      And I update start-date +2 and end-date +2 days
      And I click element "#btn_update"
     Then I should see "Please wait"
      And I wait for 1 second
      And I should not see element "#error_message"
      And I should see "Testperson5 Hermann" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson2", start-date +2, end-date +2, length 3 and offset 2 days in the Db

    # Delete
     When I click on element "div" with text "Testperson5 Hermann" and within ".gantt_ownEmployee"
      And I click element "#btn_delete"
      And I confirm alert popup
      And I wait for 1 seconds
     Then I should not see element "#error_message"
      And I should not see "Testperson5 Hermann" within ".poolTool_gantt_container"
      And there should not be a booking with starter "employee_testperson2" in the Db

