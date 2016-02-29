Feature: User views profile page
  In order to find information about a user
  As a user
  I want to

  # FIXME: when closing listing can be viewed on user profile, uncomment rest of the test
  @javascript
  Scenario: Company views his own profile page
    Given there are following users:
      | person               | is_organization | email  |
      | kassi_testperson1    | 1               | a@a.at |
      | kassi_testperson2    | 1               | b@b.at |
      | employee_testperson1 | 0               | c@c.at |
      | employee_testperson2 | 0               | d@d.at |

    # Prepare listings
    And there is a listing with title "car spare parts" from "kassi_testperson1" with category "Items" and with listing shape "Selling"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" and with listing shape "Requesting"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" and with listing shape "Selling services"
    And there is a listing with title "Housing" from "kassi_testperson2" with category "Spaces" and with listing shape "Selling"
    And there is a listing with title "bike" from "kassi_testperson1" with category "Items" and with listing shape "Requesting"
    And that listing is closed
    And there is a listing with title "sewing" from "kassi_testperson1" with category "Services" and with listing shape "Selling services"
    And that listing is closed

    # Prepare followed
    And "kassi_testperson1" follows "kassi_testperson2"
    And "kassi_testperson1" follows "employee_testperson1"

    # Prepare Employees
    And "Bosch" employs "employee_testperson1"
    And "Bosch" employs "employee_testperson2"

    And I am logged in as "kassi_testperson1"
    And I should not see "Feedback average:"
    When I open user menu
    When I follow "Profile"

    # Listings
    Then I should see "car spare parts"
    And I should see "Helsinki - Turku"
    And I should not see "Housing"
    And I should see "massage"
    And I should not see "bike"
    And I should not see "sewing"
    And I follow "Show also closed"
    And I should see "bike"

    # Following others
    And I should see "You trust 2 companies"
    And I should see "Siemens" within "#profile-followed-people-list"
    And I should see "Kassi T" within "#profile-followed-people-list"

    # Employees
    And I should see "3 employees"
    And I should see "Kassi T" within "#profile-employees-list"
    And I should see "Hermann T" within "#profile-employees-list"



  @javascript
  Scenario: Employee views his own companies profile page
    Given there are following users:
      | person               | is_organization | email  |
      | kassi_testperson1    | 1               | a@a.at |
      | kassi_testperson2    | 1               | b@b.at |
      | employee_testperson1 | 0               | c@c.at |
      | employee_testperson2 | 0               | d@d.at |

    # Prepare listings
    And there is a listing with title "car spare parts" from "kassi_testperson1" with category "Items" with availability "intern" and with listing shape "Selling"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Requesting"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" with availability "all" and with listing shape "Selling services"
    And there is a listing with title "bike" from "kassi_testperson1" with category "Items" with availability "all" and with listing shape "Requesting"
    And that listing is closed

    # Prepare followed
    And "kassi_testperson1" follows "kassi_testperson2"
    And "kassi_testperson1" follows "employee_testperson1"

    # Prepare Employees
    And "Bosch" employs "employee_testperson1"
    And "Bosch" employs "employee_testperson2"

    And I am logged in as "employee_testperson1"
    And I am on the profile page of "kassi_testperson1"

    # Listings
    Then I should see "car spare parts"
    And I should see "Helsinki - Turku"
    And I should see "massage"
    And I should not see "bike"

    # Following others
    And I should see "Siemens" within "#profile-followed-people-list"
    And I should see "Kassi T" within "#profile-followed-people-list"



  @javascript
  Scenario: Company views profile page of company who trusts the company
    Given there are following users:
      | person               | is_organization | email  |
      | kassi_testperson1    | 1               | a@a.at |
      | kassi_testperson2    | 1               | b@b.at |
      | employee_testperson1 | 0               | c@c.at |
      | employee_testperson2 | 0               | d@d.at |

    # Prepare Listings
    And there is a listing with title "car spare parts" from "kassi_testperson1" with category "Items" with availability "intern" and with listing shape "Private devices"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Private devices"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" with availability "all" and with listing shape "Selling services"
    And there is a listing with title "Housing" from "kassi_testperson2" with category "Spaces" with availability "all" and with listing shape "Selling"
    And there is a listing with title "apartment" from "kassi_testperson1" with category "Spaces" with availability "all" and with listing shape "Requesting"
    And that listing is closed

    # Prepare followed
    And "kassi_testperson1" follows "kassi_testperson2"
    And "kassi_testperson1" follows "employee_testperson1"

    # Prepare Employees
    And "Bosch" employs "employee_testperson1"
    And "Bosch" employs "employee_testperson2"

    Given I am logged in as "kassi_testperson2"
    And I am on the profile page of "kassi_testperson1"

    # Trusted user can see public and trusted listings
    Then I should see "Helsinki - Turku"
    And I should see "massage"
    And I should not see "apartment"
    And I should not see "car spare parts"

    # Trusted user cant see employees if its allowed globally
    Given the community allows others to view the employees of a company
    When I refresh the page
    Then I should see "3 employees"
    And I should see "Kassi T" within "#profile-employees-list"
    And I should see "Hermann T" within "#profile-employees-list"

    # Trusted user cant see employees
    Given the community does not allow others to view the employees of a company
    When I refresh the page
    Then I should not see "3 employees"

    # Trusted user with admin rights can see employees
    Given "kassi_testperson2" has admin rights in community "test"
    When I refresh the page
    Then I should see "3 employees"
    And I should see "Kassi T" within "#profile-employees-list"
    And I should see "Hermann T" within "#profile-employees-list"




  @javascript
  Scenario: Company views profile page of company who doesnt trusts him
    Given there are following users:
      | person               | is_organization | email  |
      | kassi_testperson1    | 1               | a@a.at |
      | kassi_testperson2    | 1               | b@b.at |
      | employee_testperson1 | 0               | c@c.at |
      | employee_testperson2 | 0               | d@d.at |

    # Prepare Listings
    And there is a listing with title "car spare parts" from "kassi_testperson1" with category "Items" with availability "intern" and with listing shape "Private devices"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Private devices"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" and with listing shape "Selling services"
    And there is a listing with title "Housing" from "kassi_testperson2" with category "Spaces" and with listing shape "Selling"
    And there is a listing with title "apartment" from "kassi_testperson1" with category "Spaces" and with listing shape "Requesting"
    And that listing is closed

    # Prepare followed
    And "kassi_testperson1" follows "employee_testperson1"

    # Prepare Employees
    And "Bosch" employs "employee_testperson1"
    And "Bosch" employs "employee_testperson2"

    Given I am logged in as "kassi_testperson2"
    And I am on the profile page of "kassi_testperson1"

    # Untrusted, logged in user can only see public listings
    Then I should see "Helsinki - Turku"
    And I should not see "massage"
    And I should not see "apartment"
    And I should not see "car spare parts"

    # Trusted user cant see employees if its allowed globally
    Given the community allows others to view the employees of a company
    When I refresh the page
    Then I should see "3 employees"
    And I should see "Kassi T" within "#profile-employees-list"
    And I should see "Hermann T" within "#profile-employees-list"

    # Trusted user cant see employees
    Given the community does not allow others to view the employees of a company
    When I refresh the page
    Then I should not see "employees"



  @javascript
  Scenario: Employee views profile page of any other company
    Given there are following users:
      | person               | is_organization | email  |
      | kassi_testperson1    | 1               | a@a.at |
      | kassi_testperson2    | 1               | b@b.at |
      | employee_testperson1 | 0               | c@c.at |
      | employee_testperson2 | 0               | d@d.at |

    # Prepare Listings
    And there is a listing with title "car spare parts" from "kassi_testperson1" with category "Items" with availability "intern" and with listing shape "Private devices"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Private devices"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" and with listing shape "Selling services"
    And there is a listing with title "Housing" from "kassi_testperson2" with category "Spaces" and with listing shape "Selling"
    And there is a listing with title "apartment" from "kassi_testperson1" with category "Spaces" and with listing shape "Requesting"
    And that listing is closed

    # Prepare followed
    And "kassi_testperson1" follows "employee_testperson1"

    # Prepare Employees
    And "Bosch" employs "employee_testperson1"

    Given I am logged in as "employee_testperson2"
    And I am on the profile page of "kassi_testperson1"

    # Untrusted, logged in user can only see public listings
    Then I should see "Helsinki - Turku"
    And I should not see "massage"
    And I should not see "apartment"
    And I should not see "car spare parts"

    # Trusted user cant see employees if its allowed globally
    Given the community allows others to view the employees of a company
    When I refresh the page
    Then I should see "2 employees"
    And I should see "Kassi T" within "#profile-employees-list"

    # Trusted user cant see employees
    Given the community does not allow others to view the employees of a company
    When I refresh the page
    Then I should not see "employees"



  @javascript
  Scenario: Logged out user views profile page of company
    Given there are following users:
      | person               | is_organization | email  |
      | kassi_testperson1    | 1               | a@a.at |
      | kassi_testperson2    | 1               | b@b.at |
      | employee_testperson1 | 0               | c@c.at |
      | employee_testperson2 | 0               | d@d.at |

    # Prepare Listings
    And there is a listing with title "car spare parts" from "kassi_testperson1" with category "Items" with availability "intern" and with listing shape "Private devices"
    And there is a listing with title "massage" from "kassi_testperson1" with category "Services" with availability "trusted" and with listing shape "Private devices"
    And there is a listing with title "Helsinki - Turku" from "kassi_testperson1" with category "Services" and with listing shape "Selling services"
    And there is a listing with title "apartment" from "kassi_testperson1" with category "Spaces" and with listing shape "Requesting"
    And that listing is closed

    # Prepare followed
    And "kassi_testperson1" follows "kassi_testperson2"
    And "kassi_testperson1" follows "employee_testperson1"

    # Prepare Employees
    And "Bosch" employs "employee_testperson1"
    And "Bosch" employs "employee_testperson2"

    # Logged out user can only see public listings
    And I am not logged in
    And I am on the profile page of "kassi_testperson1"
    Then I should see "Helsinki - Turku"
    And I should not see "car spare parts"
    And I should not see "apartment"
    And I should not see "massage"

    # Following others
    And I should see "2 trusted companies"
    And I should see "Siemens" within "#profile-followed-people-list"
    And I should see "Kassi T" within "#profile-followed-people-list"

    # Employees
    # Logged out user cant see employees
    And I should not see "employees"

    # Logged out user still cant see employees
    Given the community "test" allows others to view the employees of a company
    When I refresh the page
    Then I should not see "employees"




  @javascript
  Scenario: User views feedback in a profile page
    Given there are following users:
       | person |
       | kassi_testperson1 |
       | kassi_testperson2 |
       | kassi_testperson3 |
    And the community has payments in use via BraintreePaymentGateway
    And I am logged in as "kassi_testperson1"

    When I go to the profile page of "kassi_testperson1"
    Then I should not see "Received feedback:"
    And there is a listing with title "hammer" from "kassi_testperson1" with category "Items" and with listing shape "Selling"
    And the price of that listing is 20.00 USD
    And there is a pending request "I offer this" from "kassi_testperson2" about that listing
    And the request is accepted
    And there is feedback about that event from "kassi_testperson2" with grade "0.75" and with text "Test feedback"
    And I go to the profile page of "kassi_testperson1"
    Then I should see "1 received review"
    And I should see "100%" within "#people-testimonials"
    And I should see "Test feedback" within "#people-testimonials"

    When there is a listing with title "saw" from "kassi_testperson1" with category "Items" and with listing shape "Selling"
    And the price of that listing is 20.00 USD
    And there is a pending request "I offer this" from "kassi_testperson3" about that listing
    And the price of that listing is 20.00 USD
    And the request is accepted
    And there is feedback about that event from "kassi_testperson3" with grade "0.25" and with text "Test feedback"
    And I go to the profile page of "kassi_testperson1"
    Then I should see "50%" within "#people-testimonials"

    When there is a listing with title "drill" from "kassi_testperson1" with category "Items" and with listing shape "Selling"
    And the price of that listing is 20.00 USD
    And there is a pending request "I offer this" from "kassi_testperson2" about that listing
    And the request is accepted
    And there is feedback about that event from "kassi_testperson2" with grade "0.75" and with text "OK feedback"
    And I go to the profile page of "kassi_testperson1"
    Then I should see "67%" within "#people-testimonials"

    When there is a listing with title "tool" from "kassi_testperson1" with category "Items" and with listing shape "Selling"
    And the price of that listing is 20.00 USD
    And there is a pending request "I offer this" from "kassi_testperson3" about that listing
    And the request is accepted
    And there is feedback about that event from "kassi_testperson3" with grade "1" and with text "Excellent feedback"

    When I go to the profile page of "kassi_testperson1"
    Then I should see "75%" within "#people-testimonials"
    And I should see "Excellent feedback" within "#profile-testimonials-list"
    And I should see "OK feedback" within "#profile-testimonials-list"
    And I should see "Test feedback" within "#profile-testimonials-list"
    And I should see "Show all reviews"

  @javascript
  Scenario: Unlogged user tries to view profile page in a private community
    Given there are following users:
       | person |
       | kassi_testperson1 |
    And community "test" is private
    When I go to the profile page of "kassi_testperson1"
    Then I should see "Sign up"
