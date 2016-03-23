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


  Scenario: Can not update external existing Booking
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

  Scenario: Can not update external existing Booking
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


  Scenario: Can not update existing Booking with invalid Dates
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


  Scenario: Can not update existing Booking with conflicting Dates
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




Scenario: Employee can not update booking of anyone else
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "trusted" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And there exists an external booking for company "kassi_testperson2" from company "kassi_testperson1" and listing "Listing2" with length 5 days and offset 1 days
      And I am logged in as "employee_testperson2"
      And I am on my pool tool page
     Then I should see "Bosch" within ".poolTool_gantt_container"
     When I click on element "div" with text "Bosch" and within ".gantt_anyCompany"
     Then I should see element "#cboxLoadedContent"
      And I should not see element "#btn_update"
      And I should not see element "#btn_delete"
      And I should see "Listing2" within "#cboxLoadedContent"
      And I should see "Bosch" within "#cboxLoadedContent"
      And I should see "intern" within "#cboxLoadedContent"
    # done

Scenario: Trusted company can not update booking of others than own company members
    Given "kassi_testperson2" follows "kassi_testperson1"
      And "kassi_testperson2" follows "kassi_testperson3"
      And there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "trusted" and with listing shape "Private devices"
      And there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" and with listing shape "Renting"
      And there exists an internal booking for company "kassi_testperson2" and listing "Listing1" with reason "trusted000" and length 3 days and offset 5 days
      And there exists an internal booking for company "kassi_testperson2" and employee "employee_testperson2" and listing "Listing2" with length 3 and offset 10 days
      And I am logged in as "kassi_testperson3"
     When I go to the pool tool page of "kassi_testperson2"
      And I wait for 2 seconds

    # company admin booking
     When I click on first element "div" with text "private" and within ".gantt_privateBooking"
     Then I should see element "#cboxLoadedContent"
      And I should not see element "#btn_update"
      And I should not see element "#btn_delete"

    # company employee booking
    When I click element "#cboxClose"
      And I click on second element "div" with text "private" and within ".gantt_privateBooking"
     Then I should see element "#cboxLoadedContent"
      And I should not see element "#btn_update"
      And I should not see element "#btn_delete"


    Given there are no bookings
      And there exists an external booking for company "kassi_testperson2" from company "kassi_testperson3" and listing "Listing1" with length 3 days and offset 5 days
      And there exists an external booking for company "kassi_testperson2" from company "kassi_testperson1" and listing "Listing2" with length 3 days and offset 10 days
     When I refresh the page
      And I wait for 2 seconds

    # own booking
     When I click on element "div" with text "Continental" and within ".gantt_privateBooking"
     Then I should see element "#cboxLoadedContent"
      And I should see element "#btn_update"
      And I should see element "#btn_delete"

    # booking of another trusted company admin
     When I click element "#cboxClose"
      And I click on element "div" with text "private" and within ".gantt_privateBooking"
     Then I should see element "#cboxLoadedContent"
      And I should not see element "#btn_update"
      And I should not see element "#btn_delete"


     Given there are no bookings
      And there exists an external booking for company "kassi_testperson2" from employee "employee_testperson3" and listing "Listing1" with length 3 days and offset 5 days
      And there exists an external booking for company "kassi_testperson2" from employee "employee_testperson1" and listing "Listing2" with length 3 days and offset 10 days
     When I refresh the page
      And I wait for 2 seconds

    # booking of own employee
     When I click on first element "div" with text "Testperson6 Hank" and within ".gantt_trustedEmployee"
     Then I should see element "#cboxLoadedContent"
      And I should see element "#btn_update"
      And I should see element "#btn_delete"

    # booking of another trusted company employee
     When I click element "#cboxClose"
      And I click on element "div" with text "private" and within ".gantt_privateBooking"
     Then I should see element "#cboxLoadedContent"
      And I should not see element "#btn_update"
      And I should not see element "#btn_delete"
    # done

  #Scenario:
  #Trusted employee can not update an existing booking
