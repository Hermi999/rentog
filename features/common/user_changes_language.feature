Feature: User changes language
  In order to view the Sharetribe UI in a different language
  As a person who speaks that language
  I want to be able to change language

  @javascript
  Scenario: User changes language without logging in
    Given I am on the marketplace page
    When I follow "new-listing-link"
    And I go to the home page
    And I open language menu
    And I select "Suomi" from the language menu
    Then I should see "Lisää uusi ilmoitus!" within "#new-listing-link"

  @javascript
  Scenario: User changes language when logged in
    Given I am logged in
    And I am on the marketplace page
    And I open language menu
    And I select "Suomi" from the language menu
    Then I should see "Lisää uusi ilmoitus!" within "#new-listing-link"
