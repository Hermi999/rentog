Feature: User creates a new listing
  In order to perform a certain task using an item, a skill, or a transport, or to help others
  As a company who does not have the required item, skill, or transport, or has them and wants offer them to others
  I want to be able to offer and request an item, a favor, a transport or housing

  @javascript
  Scenario: Creating a new item request without image successfully
    Given I am logged in
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I select "Items" from listing type menu
    And I select "Tools" from listing type menu
    And I select "Requesting" from listing type menu
    And I fill in "listing_title" with "Sledgehammer"
    And I fill in "listing_description" with "My description"
    And I press "Save listing"
    Then I should see "Sledgehammer" within "#listing-title"

  @javascript
  Scenario: Creating a new item offer successfully
    Given I am logged in
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I select "Items" from listing type menu
    And I select "Tools" from listing type menu
    And I select "Lending" from listing type menu
    And I fill in "listing_title" with "My offer"
    And I fill in "listing_description" with "My description"
    And I press "Save listing"
    Then I should see "My offer" within "#listing-title"

  @javascript
  Scenario: Creating a new service request successfully
    Given I am logged in
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I select "Services" from listing type menu
    And I select "Requesting" from listing type menu
    And I fill in "listing_title" with "Massage"
    And I fill in "listing_description" with "My description"
    And I press "Save listing"
    Then I should see "Massage" within "#listing-title"

  @javascript
  Scenario: Trying to create a new request without being logged in
    Given I am not logged in
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I should see "Log in to Rentog" within "h1"

  @javascript
  @skip_phantomjs
  Scenario: Trying to create a new item request with insufficient information
    Given I am logged in
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I select "Items" from listing type menu
    And I select "Books" from listing type menu
    And I select "Requesting" from listing type menu
    And I set the expiration date to 7 months from now
    And I attach an image with invalid extension to "listing_image[image]"
    And I press "Save listing"
    Then I should see "This field is required."
    And I should see "This date must be between current time and 6 months from now."
    And I should see "The image file must be either in GIF, JPG or PNG format."

  @move_to_subdomain2
  @javascript
  Scenario: Company creates a listing and it is not visible in communities user joins
    Given there are following users:
      | person |
      | kassi_testperson3 |
    And there is a listing with title "Hammer" from "kassi_testperson3" with category "Items" and with listing shape "Requesting"
    And I am on the marketplace
    Then I should see "Hammer"
    When I move to community "test2"
    And I am on the marketplace
    Then I should not see "Hammer"
    And I log in as "kassi_testperson3"
    And I check "community_membership_consent"
    And I press "Join Rentog"
    And the system processes jobs
    And I am on the marketplace
    Then I should not see "Hammer"

  @javascript
  Scenario: Create a new listing successfully after going back and forth in the listing form
    Given I am logged in
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I select "Items" from listing type menu
    Then I should see "Category: Item"
    And I select "Tools" from listing type menu
    Then I should see "Category: Item"
    And I should see "Subcategory: Tools"
    And I select "Requesting" from listing type menu
    Then I should see "Listing type: Requesting"
    And I select "Category: Item" from listing type menu
    And I select "Services" from listing type menu
    Then I should see "Category: Services"
    And I should not see "Category: Item"
    And I select "Category: Services" from listing type menu
    And I select "Spaces" from listing type menu
    Then I should see "Category: Spaces"
    And I should not see "Category: Services"
    And I select "Selling" from listing type menu
    Then I should see "Category: Spaces"
    And I should see "Listing type: Selling"
    When I fill in "listing_title" with "My offer"
    And I fill in "listing_price" with "20"
    And I fill in "listing_description" with "My description"
    And I press "Save listing"
    Then I should see "My offer" within "#listing-title"

  @javascript
  Scenario: Company creates a new listing with price
    Given I am logged in
    When I create a new listing "Sledgehammer" with price "20.5"
    Then I should see "Sledgehammer" within "#listing-title"

  @javascript
  Scenario: Company creates a new listing with custom dropdown fields
    Given I am logged in
    And there is a custom dropdown field "House type" in community "test" in category "Spaces" with options:
      | en             | fi                   |
      | Big house      | Iso talo             |
      | Small house    | Pieni talo           |
    And there is a custom dropdown field "Balcony type" in community "test" in category "Spaces" with options:
      | en             | fi                   |
      | No balcony     | Ei parveketta        |
      | French balcony | Ranskalainen parveke |
      | Backyard       | Takapiha             |
    And there is a custom dropdown field "Service type" in community "test" in category "Services" with options:
      | en             | fi                   |
      | Cleaning       | Siivous              |
      | Delivery       | Kuljetus             |
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I select "Spaces" from listing type menu
    And I select "Selling" from listing type menu
    Then I should see "House type"
    And I should see "Balcony type"
    And I should not see "Service type"
    When I fill in "listing_title" with "My house"
    And I press "Save listing"
    Then I should see 2 validation errors
    When custom field "Balcony type" is not required
    And I am on the marketplace page
    And I follow "new-listing-link"
    And I select "Spaces" from listing type menu
    And I select "Selling" from listing type menu
    And I fill in "listing_title" with "My house"
    And I press "Save listing"
    Then I should see 1 validation errors
    When I select "Big house" from dropdown "House type"
    And I press "Save listing"
    Then I should see "House type: Big house"

  @javascript @sphinx @no-transaction
  Scenario: Company creates a new listing with custom text field
    Given I am logged in
    And there is a custom text field "Details" in community "test" in category "Spaces"
    When I follow "new-listing-link"
    And I select "Spaces" from listing type menu
    And I select "Selling" from listing type menu
    And I fill in "listing_title" with "My house"
    And I fill in text field "Details" with "Test details"
    And I select "All other companies and your employees" from "listing_availability"
    And I press "Save listing"
    And the Listing indexes are processed
    When I go to the marketplace page
    And I fill in "q" with "Test details"
    And I press "search-button"
    Then I should see "My house"

  @javascript @sphinx @no-transaction
  Scenario: Company creates a new listing with numeric field
    Given I am logged in
    And there is a custom numeric field "Area" in that community in category "Spaces" with min value 100 and with max value 2000
    When I follow "new-listing-link"
    And I select "Spaces" from listing type menu
    And I select "Selling" from listing type menu
    And I fill in "listing_title" with "My house"
    And I fill in custom numeric field "Area" with "9999"
    And I press "Save listing"
    Then I should see validation error
    When I fill in custom numeric field "Area" with "150"
    And I press "Save listing"
    Then I should see "Area: 150"

@javascript @sphinx @no-transaction
Scenario: Company creates a new listing with date field
  Given I am logged in
  And there is a custom date field "building_date_test" in that community in category "Spaces"
  When I follow "new-listing-link"
  And I select "Spaces" from listing type menu
  And I select "Selling" from listing type menu
  And I fill in "listing_title" with "My house"
  And I fill select custom date "building_date_test" with day="19", month="April" and year="2014"
  And I press "Save listing"
  Then I should see "building_date_test: Apr 19, 2014"

  @javascript @sphinx @no-transaction
  Scenario: Company creates a new listing with checkbox field
    Given I am logged in
    And there is a custom checkbox field "Amenities" in that community in category "Spaces" with options:
      | title             |
      | Internet          |
      | Wireless Internet |
      | Air Conditioning  |
      | Pool              |
      | Sauna             |
      | Hot Tub           |
    When I follow "new-listing-link"
    And I select "Spaces" from listing type menu
    And I select "Selling" from listing type menu
    And I fill in "listing_title" with "My house"
    When I check "Wireless Internet"
    And I check "Pool"
    And I check "Sauna"
    And I check "Hot Tub"
    And I press "Save listing"
    Then I should see that the listing has "Wireless Internet"
    Then I should see that the listing has "Pool"
    Then I should see that the listing has "Sauna"
    Then I should see that the listing has "Hot Tub"
    Then I should see that the listing does not have "Internet"
    Then I should see that the listing does not have "Air Conditioning"

  @javascript
  Scenario: Company creates a new listing in private community
    Given I am logged in
    And community "test" is private
    And I am on the marketplace page
    When I follow "new-listing-link"
    And I select "Items" from listing type menu
    And I select "Tools" from listing type menu
    And I select "Requesting" from listing type menu
    Then I should not see "Privacy*"
    And I fill in "listing_title" with "Sledgehammer"
    And I fill in "listing_description" with "My description"
    And I select "All other companies and your employees" from "listing_availability"
    And I press "Save listing"
    Then I should see "Sledgehammer" within "#listing-title"
    When I go to the marketplace page
    Then I should see "Sledgehammer"
    When I log out
    And I go to the marketplace page
    Then I should not see "Sledgehammer"


  @javascript
  Scenario: Employee cannot create a listing
    Given I am not logged in
    And I am on the marketplace page
    And I follow "Post a new listing"
    Then I am on the login page
    When I fill in "main_person_login" with "employee_testperson1"
    And I fill in "main_person_password" with "testi"
    And I click "#main_log_in_button"
    Then I should not see "Sign in failed."
    Then I should see "not allowed to post"
    Then I should not see "Post a new listing"

    When I go to the new listing page
    Then I should see "not allowed to post"
    And I should be on the marketplace page

  @javascript
  Scenario: Employee can create a listing
    Given the community allows employees to create listings
    And I am not logged in
    And I am on the marketplace page
    And I follow "Post a new listing"
    Then I am on the login page
    When I fill in "main_person_login" with "employee_testperson1"
    And I fill in "main_person_password" with "testi"
    And I click "#main_log_in_button"
    Then I should not see "Sign in failed."
    Then I should not see "not allowed to post"
    Then I should see "Post a new listing"

    When I go to the new listing page
    Then I should not see "not allowed to post"
    And I should be on the new listing page
