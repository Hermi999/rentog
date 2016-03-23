Feature: Employee follows and unfollows another user

  Background:
    Given there are following users:
       | person               | given_name |
       | employee_testperson2 | Me         |
       | employee_testperson1 | Them       |
       | kassi_testperson1    | Bosch      |
    And I am logged in as "employee_testperson2"

  @javascript
  Scenario: Employee follows another user
    When I go to the profile page of "employee_testperson1"
    And I follow "Follow"
    Then I should see "Following" within ".profile-action-buttons-desktop"
    When I go to my profile page
    Then I should see "Them T" within "#profile-followed-people-list"

  @javascript
  Scenario: Employee unfollows another user
    Given "employee_testperson2" follows "employee_testperson1"
    When I go to the profile page of "employee_testperson1"
    And I follow "Unfollow"
    Then I should see "Follow" within ".profile-action-buttons-desktop"
    And I should not see "Following" within ".profile-action-buttons-desktop"
    When I go to my profile page
    Then I should see "No followed people"

  @javascript
  Scenario: Employee sees all people he followed on profile page
    Given there are 10 companies with organization_name prefix "User"
    And "employee_testperson2" follows everyone
    When I go to the profile page of "employee_testperson2"
    Then I should see "You follow 15 people"

    When I follow "Show all followed people"
    Then I should not see "Show all followed people"
    Then I should see 15 user profile links

    When I follow the first "Following"
    And I refresh the page
    Then I should see "You follow 14 people"

  @javascript
  Scenario: Follower receives notification of new listing
    Given "employee_testperson1" follows "kassi_testperson1"
    And I am logged in as "kassi_testperson1"
    When I create a new listing "Jewelry" with price "899"
    And the system moves all future jobs to immediate
    And the system processes jobs
    Then "employee_testperson1@example.com" should receive an email
    When I open the email
    Then I should see "Jewelry" in the email body

