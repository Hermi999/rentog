@javascript
Feature: User views a single listing
  In order to value
  As a role
  I want feature

  Background:
    Given there are following users:
      | person |
      | kassi_testperson1 |
      | kassi_testperson2 |
    And the community has payments in use via BraintreePaymentGateway
    And there is a listing with title "Massage" from "kassi_testperson1" with category "Services" and with listing shape "Requesting"

  @only_without_asi
  Scenario: Company views a listing that he is allowed to see
    And I am on the home page
    When I follow "Massage"
    Then I should see "Massage"
    When I am logged in as "kassi_testperson1"
    And I have "2" testimonials with grade "1"
    And I am on the home page
    And I follow "Massage"
    Then I should see "Feedback"
    And I should see "100%"
    And I should see "(2/2)"

  @only_without_asi
  Scenario: Employee views a listing but cant rent it
    Given I am on the home page
    When I am logged in as "kassi_testperson2"
    And I follow "Massage"
    Then I should see "Massage"
    And I should see "Rent via your company"

    When I fill in "From" with "01/01/2050"
    And I fill in "From" with "05/01/2050"
    And I follow "Rent via your company"
    Then I should see "Send message to BBB"
    And I should see "http://rentog.lvh.me:3000/1/listings"
    And I should see "2050-01-01"
    And I should see "2050-01-05"


  @only_without_asi
  Scenario: Employee views a listing and can rent it

  @only_without_asi
  Scenario: Company views a listing with price
    And the price of that listing is 20.55 USD
    And I am on the home page
    When I follow "Massage"
    Then I should see "Massage"
    And I should see "$20.55"
    When I am logged in as "kassi_testperson1"
    And I have "2" testimonials with grade "1"
    And I am on the home page
    And I follow "Massage"
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
    And I go to the home page
    And I follow "Massage"
    Then I should not see "Add profile picture"

  Scenario: Company tries to view a listing restricted viewable to community members without logging in
    Given I am not logged in
    And privacy of that listing is "private"
    And I am on the home page
    When I go to the listing page
    Then I should see "You must sign in to view this content"

  @subdomain2
  Scenario: Company tries to view a listing from another community
    Given I am not logged in
    And that listing belongs to community "test"
    And I am on the home page
    When I go to the listing page
    Then I should see "This content is not available."

  Scenario: Company belongs to multiple communities, adds listing in one and sees it in another
    Given I am not logged in
    And privacy of that listing is "private"
    And I am on the home page
    When I go to the listing page
    Then I should see "You must sign in to view this content"

  Scenario: Company views listing created
    Given I am not logged in
    When I go to the listing page
    Then I should not see "Listing created"
    When listing publishing date is shown in community "test"
    And I go to the listing page
    Then I should see "Listing created"
