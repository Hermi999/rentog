@javascript
Feature: User books a new device
  As a user I want to book devices from the pool tool

  Background:
    Given there are following users:
      | person               | organization_name |
      | kassi_testperson1    | Bosch             |
      | kassi_testperson2    | Siemens           |
      | employee_testperson1 |                   |
      | employee_testperson2 |                   |


  Scenario: Create a new Booking with Employee
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
    Given there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
      And I should not see element "#addNewBookingForm"
     When I press "Book internal device"
      And I should see element "#addNewBookingForm"
     When I select "Hermann Testperson5" from "dd_employee"
      And I click on element "div.fluid-thumbnail-grid-image-title" with text "Listing2" and within ".home-fluid-thumbnail-grid"
      And I fill rent time for 4 days
      And I press "Create"
     Then I should not see "Choose employee" within ".page-content"
      And I should not see "Description (optional" within ".page-content"
      And I should see "Testperson5 Hermann" within ".poolTool_gantt_container"
      And there should be a booking with starter "employee_testperson2" in the Db
    #done

  Scenario: Create a new Booking with other Reason
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
    Given there is a listing with title "Listing2" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
      And I should not see element "#addNewBookingForm"
     When I press "Book internal device"
      And I should see element "#addNewBookingForm"
     When I fill in "tf_device_renter" with "Wartung"
      And I click on element "div.fluid-thumbnail-grid-image-title" with text "Listing2" and within ".home-fluid-thumbnail-grid"
      And I fill rent time for 4 days
      And I press "Create"
     Then I should not see "Choose employee" within ".page-content"
      And I should not see "Description (optional" within ".page-content"
      And I should see "Wartung" within ".poolTool_gantt_container"
      And there should be a booking with starter "kassi_testperson2" and reason "Wartung" in the Db
    #done

  Scenario: Cancel a new Booking
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     When I press "Book internal device"
     Then I should see "Cancel"
      And I should see element "#addNewBookingForm"
     When I press "Cancel"
     Then I should see "Book internal device"
      And I should not see "Choose employee" within ".page-content"
      And I should not see "Description (optional" within ".page-content"
      And I should not see element "#addNewBookingForm"
    #done

  Scenario: Only employee or reason can be chosen but not both
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     When I press "Book internal device"
      And I fill in "tf_device_renter" with "Wartung"
     Then I should see disabled element "#dd_employee"
     When I fill in "tf_device_renter" with ""
     Then I should see enabled element "#dd_employee"
     Then I should see enabled element "#tf_device_renter"
     When I select "Hermann Testperson5" from "dd_employee"
     Then I should see disabled element "#tf_device_renter"
     When I select "Please choose..." from "dd_employee"
     Then I should see enabled element "#tf_device_renter"
     Then I should see enabled element "#dd_employee"
    #done

  Scenario: Test new booking error messages
    Given there is a listing with title "Listing1" from "kassi_testperson2" with category "Tools" with availability "intern" and with listing shape "Private devices"
      And I am logged in as "kassi_testperson2"
      And I am on my pool tool page
     When I press "Book internal device"

      And I press "Create"
     Then I should see 4 validation errors

     When I fill in "tf_device_renter" with "Wartung"
      And I press "Create"
     Then I should see 2 validation errors

     When I fill in "tf_device_renter" with ""
      And I press "Create"
     Then I should see more than 2 validation errors

     When I select "Hermann Testperson5" from "dd_employee"
      And I press "Create"
     Then I should see 2 validation errors

     When I select "Please choose..." from "dd_employee"
      And I press "Create"
     Then I should see 4 validation errors

     When I fill rent time for 4 days
      And I press "Create"
     Then I should see 2 validation errors
    # done
