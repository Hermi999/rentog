@javascript
Feature: User edits an existing booking
  As a company admin I want to create, update and delete Bookings within
  the Pool Tool

  Background:
    Given there are following users:
      | person               | organization_name |
      | kassi_testperson1    | Bosch             |
      | kassi_testperson2    | Siemens           |
      | employee_testperson1 |                   |
      | employee_testperson2 |                   |


  Scenario: Try to update external existing Booking
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "trusted" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an external booking for company "kassi_testperson2" from company "kassi_testperson1" and listing "Listing2" with length 5 days and offset 1 days
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "Bosch" within ".poolTool_gantt_container"
     When I click on element "div" with text "Bosch" and within ".gantt_anyCompany"
     Then I should see element "#cboxLoadedContent"
      And I should see disabled element "#btn_update"
      And I should see disabled element "#btn_delete"
      And I should see "Listing2" within "#cboxLoadedContent"
      And I should see "Bosch" within "#cboxLoadedContent"
      And I should see "intern" within "#cboxLoadedContent"
    # done

  Scenario: Update existing Booking with Employee
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an internal booking for company "kassi_testperson2" and employee "employee_testperson2" and listing "Listing1" with length 5 and offset 1 days
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "Testperson5 Hermann" within ".poolTool_gantt_container"
     When I click on element "div" with text "Testperson5 Hermann" and within ".gantt_ownEmployee"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +2 and end-date +2 days
      And I click element "#btn_update"
     Then I should see "Please wait"
      And I wait for 1 second
      And I should not see element "#error_message"
      And I should see "Testperson5 Hermann" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson2", start-date +2, end-date +2, length 5 and offset 1 days in the Db
    # done

  Scenario: Update existing Booking with other Reason
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an internal booking for company "kassi_testperson2" and listing "Listing1" with reason "internal000" and length 5 days and offset 1 days
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason_me"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +2 and end-date +2 days
      And I click element "#btn_update"
     Then I should see "Please wait"
      And I wait for 1 second
      And I should not see element "#error_message"
      And I should see "internal000" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson2", start-date +2, end-date +2, length 5 and offset 1 days in the Db
    # done


  Scenario: Update existing Booking with invalid Dates
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an internal booking for company "kassi_testperson2" and listing "Listing1" with reason "internal000" and length 2 days and offset 1 days
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason_me"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +5 and end-date +2 days
      And I click element "#btn_update"
     Then I should see element "#error_message"
      And I should see "internal000" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson2", start-date +0, end-date +0, length 2 and offset 1 days in the Db
    # done


  Scenario: Update existing Booking with conflicting Dates
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an internal booking for company "kassi_testperson2" and listing "Listing1" with reason "internal000" and length 2 days and offset 1 days
      And there exists an internal booking for company "kassi_testperson2" and listing "Listing1" with reason "internal001" and length 5 days and offset 4 days
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     Then I should see "internal001" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason_me"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +2 and end-date +3 days
      And I click element "#btn_update"
     Then I should see element "#error_message"
      And I should see "internal000" within ".poolTool_gantt_container"
      And I should see "internal001" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson2", start-date +0, end-date +0, length 2 and offset 1 days in the Db
    # done




