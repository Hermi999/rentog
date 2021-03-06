@not_needed_for_rentog
@only_without_asi
Feature: Facebook connect
  In order to connect to Rentog with existing Facebook account
  As a user
  I want to do Facebook connect to link the accounts

  @javascript
  Scenario: Facebook connect first time, with same email in Rentog DB
    Given there are following users:
      | person     | given_name | email |
      | facebooker | Mircos     | markus@example.com |
    And community and its users are not organizations-only
    Then user "facebooker" should have "image_file_size" with value "nil"
    Given I am on the marketplace page
    When I follow log in link
    And I follow "fb-login"
    Then I should see "Successfully authorized from Facebook account"
    And I should see "Mircos"
    And user "facebooker" should not have "image_file_size" with value "nil"

  @javascript
  Scenario: Facebook connect with different email in Rentog DB
    Given there are following users:
      | person | given_name |
      | facebooker | Marcos |
    And community and its users are not organizations-only
    Then user "facebooker" should have "image_file_size" with value "nil"
    Given I am on the marketplace page
    When I follow log in link
    And I follow "fb-login"
    Then I should see "Welcome to Rentog, Markus! There's one more step to join"
    When I check "community_membership_consent"
    And I press "Join Rentog"
    Then I should see "Welcome to Rentog!"
    And I should see "Markus"
    And user "markusdotsharer123" should have "given_name" with value "Markus"
    And user "markusdotsharer123" should have "family_name" with value "Sugarberg"
    And user "markusdotsharer123" should have email "markus@example.com"
    And user "markusdotsharer123" should have "facebook_id" with value "597013691"
    And user "markusdotsharer123" should not have "image_file_size" with value "nil"

  @javascript
  Scenario: Facebook connect first time, without existing account in Rentog
    Given community and its users are not organizations-only
    And I am on the marketplace page
    When I follow log in link
    And I follow "fb-login"
    Then I should see "Welcome to Rentog, Markus! There's one more step to join"
    When I check "community_membership_consent"
    And I press "Join Rentog"
    Then I should see "Welcome to Rentog!"
    And I should see "Markus"
    And user "markusdotsharer123" should have "given_name" with value "Markus"
    And user "markusdotsharer123" should have "family_name" with value "Sugarberg"
    And user "markusdotsharer123" should have email "markus@example.com"
    And user "markusdotsharer123" should have "facebook_id" with value "597013691"
    And user "markusdotsharer123" should not have "image_file_size" with value "nil"

  @javascript
  Scenario: Facebook connect to log in when the accounts are already linked
    Given there are following users:
      | person | facebook_id | given_name |
      | marko | 597013691 | Marko |
    And community and its users are not organizations-only
    And I am on the marketplace page
    When I follow log in link
    And I follow "fb-login"
    Then I should see "Successfully authorized from Facebook account"
    And I should see "Marko"

  @javascript
  Scenario: Using Facebook connect to sign up to new community when the accounts are already linked
    Given there are following users:
      | person  | facebook_id   | given_name  |
      | marko   | 597013691     | Marko       |
    And there are following communities:
      | community     |
      | testcommunity |
    And community "testcommunity" and its users are not organizations-only

    Given I move to community "testcommunity"
      And I am on the marketplace page

     When I follow sign up link
      And I follow "signup as an employee"
      And I follow "Sign up with Facebook"
     Then I should see "Successfully authorized from Facebook account"
      And I should see "Marko"
      And I should see "I accept the terms of use"

     When I check "community_membership_consent"
      And I press "Join Rentog"
     Then I should see "Welcome to Rentog!"

  @javascript
  Scenario: User gets invitation to an invitation-only community and creates an account with FB
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And community "test" requires invite to join
    And I am not logged in
    And there is an invitation for community "test" with code "GH1JX8"
    When I arrive to sign up page with the link in the invitation email with code "GH1JX8"
    And I follow "signup as an employee"
    And I follow "Sign up with Facebook"
    Then I should see "Welcome to Rentog, Markus! There's one more step to join"
    When I check "community_membership_consent"
    And I press "Join Rentog"
    Then I should see "Welcome to Rentog!"
    And I should see "Markus"

  @javascript
  Scenario: The facebook login doesnt succeed
    Given I am on the marketplace page
    And there will be and error in my Facebook login
    When I follow log in link
    And I follow "fb-login"
    Then I should see "Could not authorize you from Facebook"

  @javascript
  Scenario: The facebook login doesnt return any email address
    Given I am on the marketplace page
    And there will be no email returned in my Facebook login
    When I follow log in link
    And I follow "fb-login"
    Then I should see "Could not get email address from Facebook"
    And I should see "Signup as company"
    And I should see "signup as an employee"
