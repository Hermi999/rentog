@javascript
Feature: User interacts with Pool Tool
  As a company admin I want to create, update and delete Bookings within
  the Pool Tool

  Background:
    Given there are following users:
      | person               | organization_name |
      | kassi_testperson1    | Bosch             |
      | kassi_testperson2    | Siemens           |
      | employee_testperson1 |                   |
      | employee_testperson2 |                   |

  Scenario: Initial Pool Tool Access
    Given I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "Your company has no (open) devices yet"
      And I should see "create a new listing here"
     When I follow "here" within "#create_new_listing"
     Then I should see "Post a new listing"

    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
    Given there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "trusted" and with listing shape "Renting"
    Given there is a listing with title "Listing3" from "kassi_testperson1" with category "Tools" with availability "all" and with listing shape "Renting"
      And I am on my pool tool page
     Then I should see "Pool Management Tool"
      And I should not see element "#addNewBookingForm"
      And I should see "Listing1"
      And I should see "intern"
      And I should see "Listing2"
      And I should see "trusted"
      And I should see "Listing3"
      And I should see "all"
    #done


  Scenario: Create a new Booking with Employee
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
    Given there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
      And I should not see element "#addNewBookingForm"
     When I press "Add new booking"
      And I should see element "#addNewBookingForm"
     When I select "Kassi Testperson3" from "dd_employee"
      And I click on element "div.fluid-thumbnail-grid-image-title" with text "Listing2" and within ".home-fluid-thumbnail-grid"
      And I fill rent time for 4 days
      And I press "Create"
     Then I should not see "Create" within ".page-content"
      And I should see "Testperson3 Kassi" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson1" in the Db
    #done

  Scenario: Create a new Booking with other Reason
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
    Given there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
      And I should not see element "#addNewBookingForm"
     When I press "Add new booking"
      And I should see element "#addNewBookingForm"
     When I fill in "tf_device_renter" with "Wartung"
      And I click on element "div.fluid-thumbnail-grid-image-title" with text "Listing2" and within ".home-fluid-thumbnail-grid"
      And I fill rent time for 4 days
      And I press "Create"
     Then I should not see "Create" within ".page-content"
      And I should see "Wartung" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson1" and reason "Wartung" in the Db
    #done

  Scenario: Cancel a new Booking
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     When I press "Add new booking"
     Then I should see "Cancel"
      And I should see element "#addNewBookingForm"
     When I press "Cancel"
     Then I should see "Add new booking"
      And I should not see "Create" within ".page-content"
      And I should not see element "#addNewBookingForm"
    #done

  Scenario: Only employee or reason can be chosen but not both
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     When I press "Add new booking"
      And I fill in "tf_device_renter" with "Wartung"
     Then I should see disabled element "#dd_employee"
     When I fill in "tf_device_renter" with ""
     Then I should see enabled element "#dd_employee"
     Then I should see enabled element "#tf_device_renter"
     When I select "Kassi Testperson3" from "dd_employee"
     Then I should see disabled element "#tf_device_renter"
     When I select "Please choose..." from "dd_employee"
     Then I should see enabled element "#tf_device_renter"
     Then I should see enabled element "#dd_employee"
    #done

  Scenario: Test new booking error messages
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     When I press "Add new booking"

      And I press "Create"
     Then I should see 4 validation errors

     When I fill in "tf_device_renter" with "Wartung"
      And I press "Create"
     Then I should see 2 validation errors

     When I fill in "tf_device_renter" with ""
      And I press "Create"
     Then I should see 4 validation errors

     When I select "Kassi Testperson3" from "dd_employee"
      And I press "Create"
     Then I should see 2 validation errors

     When I select "Please choose..." from "dd_employee"
      And I press "Create"
     Then I should see 4 validation errors

     When I fill rent time for 4 days
      And I press "Create"
     Then I should see 2 validation errors
    # done

  Scenario: Try to update external existing Booking
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "trusted" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there exists an external booking for company "kassi_testperson1" from company "kassi_testperson2" and listing "Listing2" with length 5 days and offset 1 days
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "Siemens" within ".poolTool_gantt_container"
     When I click on element "div" with text "Siemens" and within ".gantt_anyCompany"
     Then I should see element "#cboxLoadedContent"
      And I should see disabled element "#btn_update"
      And I should see disabled element "#btn_delete"
      And I should see "Listing2" within "#cboxLoadedContent"
      And I should see "Siemens" within "#cboxLoadedContent"
      And I should see "intern" within "#cboxLoadedContent"
    # done

  Scenario: Update existing Booking with Employee
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there exists an internal booking for company "kassi_testperson1" and employee "employee_testperson1" and listing "Listing1" with length 5 and offset 1 days
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "Testperson3 Kassi" within ".poolTool_gantt_container"
     When I click on element "div" with text "Testperson3 Kassi" and within ".gantt_ownEmployee"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +2 and end-date +2 days
      And I press "Update"
     Then I should see "Please wait"
      And I wait for 1 second
      And I should not see element "#error_message"
      And I should see "Testperson3 Kassi" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson1", start-date +2, end-date +2, length 5 and offset 1 days in the Db
    # done

  Scenario: Update existing Booking with other Reason
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there exists an internal booking for company "kassi_testperson1" and listing "Listing1" with reason "internal000" and length 5 days and offset 1 days
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +2 and end-date +2 days
      And I press "Update"
     Then I should see "Please wait"
      And I wait for 1 second
      And I should not see element "#error_message"
      And I should see "internal000" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson1", start-date +2, end-date +2, length 5 and offset 1 days in the Db
    # done


  Scenario: Update existing Booking with invalid Dates
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there exists an internal booking for company "kassi_testperson1" and listing "Listing1" with reason "internal000" and length 2 days and offset 1 days
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +5 and end-date +2 days
      And I press "Update"
     Then I should see element "#error_message"
      And I should see "internal000" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson1", start-date +0, end-date +0, length 2 and offset 1 days in the Db
    # done


  Scenario: Update existing Booking with conflicting Dates
    Given there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there exists an internal booking for company "kassi_testperson1" and listing "Listing1" with reason "internal000" and length 2 days and offset 1 days
      And there exists an internal booking for company "kassi_testperson1" and listing "Listing1" with reason "internal001" and length 5 days and offset 4 days
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     Then I should see "internal001" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason"
     Then I should see element "#cboxLoadedContent"
     When I update start-date +2 and end-date +3 days
      And I press "Update"
     Then I should see "Please wait"
      And I should see element "#error_message"
      And I should see "internal000" within ".poolTool_gantt_container"
      And I should see "internal001" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson1", start-date +0, end-date +0, length 2 and offset 1 days in the Db
    # done

  @skip_phantomjs
  Scenario: Delete existing Booking with Employee
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
      And there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there exists an internal booking for company "kassi_testperson1" and employee "employee_testperson1" and listing "Listing1" with length 2 and offset 1 days
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "Testperson3 Kassi" within ".poolTool_gantt_container"
     When I click on element "div" with text "Testperson3 Kassi" and within ".gantt_ownEmployee"
     Then I should see element "#cboxLoadedContent"
     When I press "Delete"
      And I confirm alert popup
      And I wait for 1 seconds
     Then I should not see element "#error_message"
      And I should not see "Testperson3 Kassi" within ".poolTool_gantt_container"
      And there should not be a booking with starter "employee_testperson1" in the Db
    # done

  @skip_phantomjs
  Scenario: Delete existing Booking with other Reason
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
      And there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there exists an internal booking for company "kassi_testperson1" and listing "Listing1" with reason "internal000" and length 2 days and offset 1 days
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     Then I should see "internal000" within ".poolTool_gantt_container"
     When I click on element "div" with text "internal000" and within ".gantt_otherReason"
     Then I should see element "#cboxLoadedContent"
     When I press "Delete"
      And I confirm alert popup
      And I wait for 1 seconds
     Then I should not see element "#error_message"
      And I should not see "internal000" within ".poolTool_gantt_container"
      And there should not be a booking with starter "kassi_testperson1" and reason "internal000" in the Db
    # done

  @skip_phantomjs
  Scenario: Create, update and delete a booking in a row
    # Create
    Given I will confirm all following confirmation dialogs in this page if I am running PhantomJS
      And there is a listing with title "Listing1" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And there is a listing with title "Listing2" from "kassi_testperson1" with category "Tools" with availability "intern" and with listing shape "Renting"
      And I am logged in as "kassi_testperson1"
      And I am on my pool tool page
     When I press "Add new booking"
      And I select "Kassi Testperson3" from "dd_employee"
      And I click on element "div.fluid-thumbnail-grid-image-title" with text "Listing2" and within ".home-fluid-thumbnail-grid"
      And I fill booking start-date +2 and end-date +5 days
      And I press "Create"
     Then I should see "Testperson3 Kassi" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson1" in the Db

    # Update
     When I click on element "div" with text "Testperson3 Kassi" and within ".gantt_ownEmployee"
      And I update start-date +2 and end-date +2 days
      And I press "Update"
     Then I should see "Please wait"
      And I wait for 1 second
      And I should not see element "#error_message"
      And I should see "Testperson3 Kassi" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson1", start-date +2, end-date +2, length 3 and offset 2 days in the Db

    # Delete
     When I click on element "div" with text "Testperson3 Kassi" and within ".gantt_ownEmployee"
      And I press "Delete"
      And I confirm alert popup
      And I wait for 1 seconds
     Then I should not see element "#error_message"
      And I should not see "Testperson3 Kassi" within ".poolTool_gantt_container"
      And there should not be a booking with starter "employee_testperson1" in the Db

