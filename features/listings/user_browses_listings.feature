Feature: User browses listings
  In order to find out what kind of offers and requests there are available in Sharetribe
  As a person who needs something or has something
  I want to be able to browse offers and requests


  @javascript @sphinx @no-transaction
  Scenario: Visitor browses offers page
    Given there are following users:
      | person |
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "car spare parts" from "kassi_testperson2" with category "Items" and with listing shape "Selling"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" and with listing shape "Selling services"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" and with listing shape "Selling services"
    And there is a listing with title "Apartment" from "kassi_testperson2" with category "Spaces" and with listing shape "Selling"
    And there is a listing with title "saw" from "kassi_testperson2" with category "Items" and with listing shape "Lending"
    And there is a listing with title "axe" from "kassi_testperson2" with category "Items" and with listing shape "Lending"
    And that listing is closed
    And there is a listing with title "toolbox" from "kassi_testperson2" with category "Items" and with listing shape "Requesting"
    And I am on the marketplace page
    And the Listing indexes are processed
    When I choose to view only listing shape "Lending"
    And I should not see "car spare parts"
    And I should not see "massage"
    And I should not see "Helsinki - Turku"
    And I should not see "Apartment"
    And I should see "saw"
    And I should not see "axe"
    And I should not see "toolbox"
    When I choose to view only listing shape "Selling"
    And I should see "car spare parts"
    And I should see "Apartment"
    And I should not see "massage"
    And I should not see "Helsinki - Turku"
    And I should not see "saw"
    And I should not see "axe"
    And I should not see "toolbox"
    And I follow "Services"
    And I should not see "massage"
    And I should not see "Helsinki - Turku"
    And I should not see "car spare parts"
    And I should not see "Apartment"
    And I should not see "saw"
    And I should not see "axe"
    And I should not see "toolbox"
    When I choose to view only listing shape "All listing types"
    And I should not see "car spare parts"
    And I should see "massage"
    And I should see "Helsinki - Turku"
    And I should not see "Apartment"
    And I should not see "saw"
    And I should not see "axe"
    And I should not see "toolbox"

  @javascript @sphinx @no-transaction
  Scenario: Visitor browses requests page
    Given there are following users:
      | person |
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "car spare parts" from "kassi_testperson2" with category "Items" and with listing shape "Requesting"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" and with listing shape "Requesting"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" and with listing shape "Requesting"
    And there is a listing with title "Apartment" from "kassi_testperson2" with category "Spaces" and with listing shape "Requesting"
    And there is a listing with title "saw" from "kassi_testperson2" with category "Items" and with listing shape "Requesting"
    And there is a listing with title "axe" from "kassi_testperson2" with category "Items" and with listing shape "Requesting"
    And that listing is closed
    And there is a listing with title "toolbox" from "kassi_testperson2" with category "Items" and with listing shape "Selling"
    And the Listing indexes are processed

    When I am on the marketplace page
    And I choose to view only listing shape "Request"
    Then I should see "car spare parts"
    And I should see "massage"
    And I should see "Helsinki - Turku"
    And I should see "Apartment"
    And I should see "saw"
    And I should not see "axe"
    And I should not see "toolbox"
    And I follow "Items"
    And I should see "car spare parts"
    And I should not see "massage"
    And I should not see "Helsinki - Turku"
    And I should not see "Apartment"
    And I should see "saw"
    And I should not see "axe"
    And I should not see "toolbox"
    And I follow "Services"
    And I should not see "car spare parts"
    And I should see "massage"
    And I should see "Helsinki - Turku"
    And I should not see "Apartment"
    And I should not see "saw"
    And I should not see "axe"
    And I should not see "toolbox"
    When I choose to view only listing shape "All listing types"
    And I should not see "car spare parts"
    And I should see "massage"
    And I should see "Helsinki - Turku"
    And I should not see "Apartment"
    And I should not see "saw"
    And I should not see "axe"
    And I should not see "toolbox"


  @javascript @sphinx @no-transaction
  Scenario: Visitor should only see public listings
    Given there are following users:
      | person |
      | kassi_testperson1 |
      | kassi_testperson2 |
    # intern listings
    And there is a listing with title "items_intern_requesting" from "kassi_testperson2" with category "Items" with availability "intern" and with listing shape "Requesting"
    And there is a listing with title "items_intern_renting" from "kassi_testperson1" with category "Items" with availability "intern" and with listing shape "Renting"
    And there is a listing with title "services_intern_lending" from "kassi_testperson1" with category "Services" with availability "intern" and with listing shape "Lending"
    And there is a listing with title "spaces_intern_selling" from "kassi_testperson2" with category "Spaces" with availability "intern" and with listing shape "Selling"

    # trusted listings
    And there is a listing with title "items_trusted_requesting" from "kassi_testperson2" with category "Items" with availability "trusted" and with listing shape "Requesting"
    And there is a listing with title "items_trusted_renting" from "kassi_testperson1" with category "Items" with availability "trusted" and with listing shape "Renting"
    And there is a listing with title "services_trusted_lending" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Lending"
    And there is a listing with title "spaces_trusted_selling" from "kassi_testperson2" with category "Spaces" with availability "trusted" and with listing shape "Selling"

    # public listings
    And there is a listing with title "items_all_requesting" from "kassi_testperson2" with category "Items" and with listing shape "Requesting"
    And there is a listing with title "items_all_renting" from "kassi_testperson1" with category "Items" and with listing shape "Renting"
    And there is a listing with title "services_all_lending" from "kassi_testperson1" with category "Services" and with listing shape "Lending"
    And there is a listing with title "spaces_all_selling" from "kassi_testperson2" with category "Spaces" and with listing shape "Selling"
    And the Listing indexes are processed

    When I am on the marketplace page
    When I choose to view only listing shape "All listing types"

    Then I should see "items_all_requesting"
    And I should see "items_all_renting"
    And I should see "services_all_lending"
    And I should see "spaces_all_selling"

    And I should not see "items_trusted_requesting"
    And I should not see "items_trusted_renting"
    And I should not see "services_trusted_lending"
    And I should not see "spaces_trusted_selling"

    And I should not see "items_intern_requesting"
    And I should not see "items_intern_renting"
    And I should not see "services_intern_lending"
    And I should not see "spaces_intern_selling"


@javascript @sphinx @no-transaction
  Scenario: Visitor should not see any listing on restricted marketplace
    Given there are following users:
      | person |
      | kassi_testperson1 |
      | kassi_testperson2 |
    # intern listings
    And there is a listing with title "items_intern_requesting" from "kassi_testperson2" with category "Items" with availability "intern" and with listing shape "Requesting"
    And there is a listing with title "items_intern_renting" from "kassi_testperson1" with category "Items" with availability "intern" and with listing shape "Renting"
    And there is a listing with title "services_intern_lending" from "kassi_testperson1" with category "Services" with availability "intern" and with listing shape "Lending"
    And there is a listing with title "spaces_intern_selling" from "kassi_testperson2" with category "Spaces" with availability "intern" and with listing shape "Selling"

    # trusted listings
    And there is a listing with title "items_trusted_requesting" from "kassi_testperson2" with category "Items" with availability "trusted" and with listing shape "Requesting"
    And there is a listing with title "items_trusted_renting" from "kassi_testperson1" with category "Items" with availability "trusted" and with listing shape "Renting"
    And there is a listing with title "services_trusted_lending" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Lending"
    And there is a listing with title "spaces_trusted_selling" from "kassi_testperson2" with category "Spaces" with availability "trusted" and with listing shape "Selling"

    # public listings
    And there is a listing with title "items_all_requesting" from "kassi_testperson2" with category "Items" and with listing shape "Requesting"
    And there is a listing with title "items_all_renting" from "kassi_testperson1" with category "Items" and with listing shape "Renting"
    And there is a listing with title "services_all_lending" from "kassi_testperson1" with category "Services" and with listing shape "Lending"
    And there is a listing with title "spaces_all_selling" from "kassi_testperson2" with category "Spaces" and with listing shape "Selling"
    And the Listing indexes are processed

    When I am on the restricted marketplace
    When I choose to view only listing shape "All listing types"

    Then I should not see "items_all_requesting"
    And I should not see "items_all_renting"
    And I should not see "services_all_lending"
    And I should not see "spaces_all_selling"

    And I should not see "items_trusted_requesting"
    And I should not see "items_trusted_renting"
    And I should not see "services_trusted_lending"
    And I should not see "spaces_trusted_selling"

    And I should not see "items_intern_requesting"
    And I should not see "items_intern_renting"
    And I should not see "services_intern_lending"
    And I should not see "spaces_intern_selling"
