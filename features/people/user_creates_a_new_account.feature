@javascript
Feature: User creates a new account
  In order to log in to Rentog
  As a person who does not have an account in Rentog
  I want to create a new account in Rentog

  Background:
    Given I am not logged in
    And I am on the signup page

  Scenario: Creating a new company account successfully
    Then I should not see "The access to Rentog is restricted."
    And I fill in "person[organization_name]" with "Hofer"
    And I fill in "First name" with "Hermann"
    And I fill in "Last name" with "Wagner"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "Please confirm your email"
    When wait for 1 seconds
    Then I should receive 1 email
    When I open the email
    And I click the first link in the email
    Then I should have 2 emails
    And I should see "The email you entered is now confirmed"
    And I should not see my username
    And Most recently created user should be member of "test" community with its latest consent accepted

    # Unconfirmed user can create a listing or make transaction if community settings allow this
    When I follow "Post a new listing"
    Then I should see "Select category"
    And I should not see "Rentog requires people to be verified manually by admin before they can post listings."

    Given the community has payments in use via BraintreePaymentGateway
    And there is a listing with title "Omicron" from "kassi_testperson2" with category "Services" and with listing shape "Renting"
    When I am on the home page
    And I follow "Omicron"
    Then I should see "Rent"
    And I should not see "Only companies verified by the Rentog Admin can make transactions. You are not verified yet. This will be done soon by the admin!"

    # Unconfirmed company can't create a listing or make transaction
    Given only verified users can post listings in this community
    When I follow "Post a new listing"
    Then I should not see "Select category"
    And I should see "Rentog requires people to be verified manually by admin before they can post listings."
    And I should see "You have not yet been verified."

    When I am on the home page
    And I follow "Omicron"
    And I should see "Only companies verified by the Rentog Admin can make transactions. You are not verified yet. This will be done soon by the admin!"

    # After log in as admin and verification of the company, the company can post listings
    When I log out
    Given "kassi_testperson1" has admin rights in community "test"
    And I am logged in as "kassi_testperson1"
    When I wait for 1 seconds
    Given I am on the manage members admin page
    And I verify user "Hofer" as a seller
    And I log out
    Given I am logged in as organization "Hofer"
    When I follow "Post a new listing"
    Then I should see "Select category"
    And I should not see "Rentog requires people to be verified manually by admin before they can post listings."
    When I am on the home page
    And I follow "Omicron"
    Then I should see "Rent"
    And I should not see "Only companies verified by the Rentog Admin can make transactions. You are not verified yet. This will be done soon by the admin!"


  Scenario: Creating a new employee account successfully
    Given I am on the signup page
    Then I should not see "The access to Rentog is restricted."
    When I click "#signup_employee"
    And I fill in "First name" with "Siemens"
    And I fill in "Last name" with "Namez"
    And I fill in "Your organization admins email address" with "kassi_testperson2@example.com"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"

    # email confirmation
    Then I should see "Please confirm your email"
    When wait for 1 seconds
    Then I should receive 1 email
    When I open the email
    And I click the first link in the email
    Then I should have 2 emails
    And I should see "The email you entered is now confirmed"
    And I should not see my username
    And Most recently created user should be member of "test" community with its latest consent accepted

    # company admin verification
    Then I should see "You have to be verified by your company admin."
    And I should see "Your company administrator needs to verify you"
    And I go to the home page
    Then I should see "Your company administrator needs to verify you"
    When the company-admin verifies employee
    And I go to the home page
    Then I should not see "Your company administrator needs to verify you"

    #Rentog requires people to be verified manually by admin before they can post listings. You have not yet been verified. Please contact the admin to be verified.

  # Scenario: Trying to create company account with unavailable username
  #   When I fill in "person[username]" with "kassi_testperson2"
  #   And I fill in "Organization name" with "Siemens"
  #   And I fill in "person_password1" with "test"
  #   And I fill in "Confirm password" with "test"
  #   And I fill in "Email address" with random email
  #   And I press "Create account"
  #   Then I should see "This username is already in use."

  # Scenario: Trying to create company account with invalid username
  #   When I fill in "person[username]" with "sirkka-liisa"
  #   And I fill in "Organization name" with "Siemens"
  #   And I fill in "person_password1" with "test"
  #   And I fill in "Confirm password" with "test"
  #   And I fill in "Email address" with random email
  #   And I press "Create account"
  #   Then I should see "Username is invalid."

  Scenario: Trying to create company account with unavailable email
    When I fill in "Organization name" with "Siemens"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with "kassi_testperson2@example.com"
    And I press "Create account"
    Then I should see "The email you gave is already in use."

  Scenario: Trying to create an company without First name and last name
    Given I am on the signup page
    When I fill in "person[organization_name]" with "TestCompany"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "This field is required."
    # Community where First and Last name are not required
    When given name and last name are not required in community "test"
    And I am on the signup page
    When I fill in "person[organization_name]" with "TestCompany1"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    And wait for 1 seconds
    Then I should receive 1 email
    When I open the email
    And I click the first link in the email
    And wait for 1 seconds
    Then I should have 2 emails
    And I should see "The email you entered is now confirmed"

  Scenario: Trying to create an company account without Organization name
    Given I am on the signup page
    When I fill in "First name" with "Hermann"
    And I fill in "Last name" with "Wagner"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "This field is required."

  Scenario: Trying to create an employee account without choosing an organization
    Given I am on the signup page
    Then I should not see "The access to Rentog is restricted."
    When I click "#signup_employee"
    And I fill in "First name" with "Siemens"
    And I fill in "Last name" with "Namez"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "The organization you've given does not exist"

  @subdomain2
  Scenario: Seeing info of community's email restriction
    Then I should see "The access to Rentog is restricted."



