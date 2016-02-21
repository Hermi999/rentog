@javascript
Feature: User views a single listing
  In order to value
  As a role
  I want feature

  Background:
    Given there are following users:
      | person |
      | kassi_testperson1    |
      | kassi_testperson2    |
      | employee_testperson1 |
    And the community has payments in use via BraintreePaymentGateway
    And there is a listing with title "services_public_requesting" from "kassi_testperson1" with category "Services" and with listing shape "Requesting"

  @only_without_asi
  Scenario: Company views a listing that it is allowed to see
    And I am on the marketplace page
    When I follow "services_public_requesting"
    Then I should see "services_public_requesting"
    When I am logged in as "kassi_testperson1"
    And I have "2" testimonials with grade "1"
    And I am on the marketplace page
    And I follow "services_public_requesting"
    Then I should see "Feedback"
    And I should see "100%"
    And I should see "(2/2)"



  @only_without_asi
  Scenario: Trusted Company tries to view an intern listing
    And there is a listing with title "services_intern_requesting" from "kassi_testperson1" with category "Services" with availability "intern" and with listing shape "Renting"
    And "kassi_testperson1" trusts "kassi_testperson2"

    When I am logged in as "kassi_testperson2"
    And I am on the profile page of "kassi_testperson1"
    Then I should see "Siemens" within "#profile-followed-people-list"

    When I am on the marketplace page
    Then I should not see "services_intern_requesting"

    When I go to the listing page
    Then I should not see "services_intern_requesting"
    And I should see "You are not authorized to view this content"
    And I should see "All listing types"

  @only_without_asi
  Scenario: Untrusted Company tries to view an intern listing
    And there is a listing with title "services_intern_requesting" from "kassi_testperson1" with category "Services" with availability "intern" and with listing shape "Renting"

    When I am logged in as "kassi_testperson2"
    And I am on the profile page of "kassi_testperson1"
    Then I should not see "Siemens" within ".page-content"

    When I am on the marketplace page
    Then I should not see "services_intern_requesting"

    When I go to the listing page
    Then I should not see "services_intern_requesting"
    And I should see "You are not authorized to view this content"
    And I should see "All listing types"



  @only_without_asi
  Scenario: Trusted Company views an trusted listing
    And there is a listing with title "services_trusted_requesting" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Renting"
    And "kassi_testperson1" trusts "kassi_testperson2"

    When I am logged in as "kassi_testperson2"
    And I am on the profile page of "kassi_testperson1"
    Then I should see "Siemens" within "#profile-followed-people-list"

    When I am on the restricted marketplace page
    Then I should see "services_trusted_requesting"

    When I go to the listing page
    Then I should see "services_trusted_requesting"
    And I should see "Rent"

  @only_without_asi
  Scenario: Untrusted Company cant view any trusted listing
    And there is a listing with title "services_trusted_requesting" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Renting"

    When I am logged in as "kassi_testperson2"
    And I am on the profile page of "kassi_testperson1"
    Then I should not see "Siemens" within ".page-content"

    When I am on the restricted marketplace page
    Then I should not see "services_trusted_requesting"



  @only_without_asi
  Scenario: Employee views a listing but cant rent it
    Given I am on the marketplace page
    And there is a listing with title "Omicron" from "kassi_testperson2" with category "Services" and with listing shape "Renting"
    When I log in as "employee_testperson1"
    And I follow "Omicron"
    Then I should see "Omicron"
    And I should see "Rent via your company"
    And I press "Rent via your company"
    # Bosch is company, Siemens renter
    Then I should see "Send message to Bosch"


  @only_without_asi
  Scenario: Employee views a listing and can rent it
    Given the community allows employees to buy listings
    And there is a listing with title "Omicron" from "kassi_testperson2" with category "Services" and with listing shape "Renting"
    And I am on the marketplace
    When I log in as "employee_testperson1"
    And I follow "Omicron"
    Then I should see "Omicron"
    And I should see "Rent"
    And I press "Rent"
    Then I should see "Rent this item"
    # Bosch is company, Siemens renter
    And I should see "Message to Siemens"

  @only_without_asi
  Scenario: Company views a listing with price
    And the price of that listing is 20.55 USD
    And I am on the marketplace page
    When I follow "services_public_requesting"
    Then I should see "services_public_requesting"
    And I should see "$20.55"
    When I log in as "kassi_testperson1"
    And I have "2" testimonials with grade "1"
    And I am on the marketplace page
    And I follow "services_public_requesting"
    Then I should see "Feedback"
    And I should see "100%"
    And I should see "(2/2)"

  @skip_phantomjs
  Scenario: Company sees the avatar in listing page
    Given I am logged in as "kassi_testperson1"
    When I open user menu
    When I follow "Settings"
    And I attach a valid image file to "avatar_file"
    And I press "Save information"
    And I go to the marketplace page
    And I follow "services_public_requesting"
    Then I should not see "Add profile picture"

  Scenario: Company tries to view a listing restricted viewable to community members without logging in
    Given I am not logged in
    And this community is private
    And I am on the marketplace page
    When I go to the listing page
    Then I should see "You must log in to view this content"

  Scenario: Company views listing created
    Given I am not logged in
    When I go to the listing page
    Then I should not see "Listing created"
    When listing publishing date is shown in community "test"
    And I go to the listing page
    Then I should see "Listing created"
