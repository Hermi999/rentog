Feature: User joins invite only community
  In order to maintain trust in closed community
  As a community administrator
  I want that new users can join only if they have valid invite code

  # WARNING: The Step "there should be an active ajax request" is unreliable
  # for local tests you can remove it
  @javascript
  Scenario: Employee has valid invite code
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And community "test" requires invite to join
    And I am not logged in
    And I am on the signup page
    And I follow "Signup as employee"
    And there is an invitation for community "test" with code "GH1JX8"
    When I fill in "Invitation code" with "GH1JX8"
    And I remove the focus
    Then there should be an active ajax request
    When ajax requests are completed
    And I fill in "First name" with "Testmanno"
    And I select "Siemens" from "person[organization_name2]"
    And I fill in "Last name" with "Namez"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should not see "The invitation code is not valid."
    And I should not see "This field is required."
    And Most recently created user should be member of "test" community with status "pending_email_confirmation" and its latest consent accepted with invitation code "GH1JX8"
    And Invitation with code "GH1JX8" should have 0 usages_left

  # WARNING: The Step "there should be an active ajax request" is unreliable
  # for local tests you can remove it
  @javascript
  Scenario: Company has valid invite code
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And community "test" requires invite to join
    And I am not logged in
    And I am on the signup page
    And there is an invitation for community "test" with code "GH1JX8"
    When I fill in "Invitation code" with "GH1JX8"
    And I remove the focus
    Then there should be an active ajax request
    When ajax requests are completed
    And I fill in "Organization name" with "abcd"
    And I fill in "First name" with "Testmanno"
    And I fill in "Last name" with "Namez"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should not see "The invitation code is not valid."
    And I should not see "This field is required."
    And Most recently created user should be member of "test" community with status "pending_email_confirmation" and its latest consent accepted with invitation code "GH1JX8"
    And Invitation with code "GH1JX8" should have 0 usages_left

  @javascript
  Scenario: Company tries to register without valid invite code
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And community "test" requires invite to join
    And I am not logged in
    And I am on the signup page
    And I fill in "First name" with "Testmanno"
    And I fill in "Last name" with "Namez"
    And I fill in "Organization name" with "abcd"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "This field is required."

  @javascript
  Scenario: Employee tries to register without valid invite code
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And community "test" requires invite to join
    And I am not logged in
    And I am on the signup page
    And I follow "Signup as employee"
    And I fill in "First name" with "Testmanno"
    And I fill in "Last name" with "Namez"
    And I select "Siemens" from "person[organization_name2]"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "This field is required."


  @javascript
  Scenario: Company tries to register with expired invite
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And community "test" requires invite to join
    And I am not logged in
    And I am on the signup page
    And there is an invitation for community "test" with code "GH1JX8" with 0 usages left
    When I fill in "Invitation code" with "gh1jx8"
    And I fill in "First name" with "Testmanno"
    And I fill in "Last name" with "Namez"
    And I fill in "Organization name" with "abcd"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "The invitation code is not valid."

  @javascript
  Scenario: Employee tries to register with expired invite
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And community "test" requires invite to join
    And I am not logged in
    And I am on the signup page
    And I follow "Signup as employee"
    And there is an invitation for community "test" with code "GH1JX8" with 0 usages left
    When I fill in "Invitation code" with "gh1jx8"
    And I select "Siemens" from "person[organization_name2]"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should see "The invitation code is not valid."

  @javascript
  Scenario: Company and Employee should not see invitation code in the form, if its not needed
    Given I am not logged in
    And community "test" does not require invite to join
    And I am on the signup page
    Then I should not see "Invitation code"
    Given I am on the signup page
    And I follow "Signup as employee"
    Then I should not see "Invitation code"
    Given community "test" requires invite to join
    And I am on the signup page
    Then I should see "Invitation code"

  @javascript
  Scenario: Company joins a community where invitation code is not necessary with an invitation code
    Given there are following users:
      | person |
      | kassi_testperson1 |
    And I am not logged in
    And community "test" does not require invite to join
    And there is an invitation for community "test" with code "GH1JX8" with 1 usages left
    And I go to the registration page with invitation code "GH1JX8"
    Then I should not see "Invitation code"
    And I fill in "Organization name" with "Testmanno2"
    And I fill in "First name" with "Testmanno"
    And I fill in "Last name" with "Namez"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person_terms"
    And I press "Create account"
    Then I should not see "The invitation code is not valid."
    And I should not see "This field is required."
    And I should see "Please confirm your email"
    And I should receive 1 email
    When I open the email
    And I follow "confirmation" in the email
    Then I should see "The email you entered is now confirmed"
    And I should have 2 emails
    And Most recently created user should be member of "test" community with its latest consent accepted with invitation code "GH1JX8"
    And Invitation with code "GH1JX8" should have 0 usages_left
