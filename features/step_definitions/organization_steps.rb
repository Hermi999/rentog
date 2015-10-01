Given /^community(?: "(.*)")? allows only organizations$/ do |community|
  if community.nil?
    c = Community.first
  else
    c = Community.where(ident: community).first
  end
  c.only_organizations = true
  c.save!
end

Given /^community(?: "(.*)")? is not organizations-only$/ do |community|
  if community.nil?
    c = Community.first
  else
    c = Community.where(ident: community).first
  end
  c.only_organizations = false
  c.save!
end

Given /^community(?: "(.*)")? and its users are not organizations-only$/ do |community|
  if community.nil?
    c = Community.first
  else
    c = Community.where(ident: community).first
  end
  c.only_organizations = false
  c.save!

  Person.update_all :is_organization => false
end

Given /^I signup as an organization "(.*?)" with name "(.*?)"$/ do |org_username, org_display_name|
  steps %Q{
    Given I am on the signup page
    When I fill in "person[username]" with "#{org_username}"
    And I fill in "person[organization_name]" with "#{org_display_name}"
    And I fill in "person_password1" with "test"
    And I fill in "Confirm password" with "test"
    And I fill in "Email address" with random email
    And I check "person[terms]"
    And I press "Create company account"
  }
end

Then /^there should be an organization account "(.*?)"$/ do |org_username|
  o = Person.find_by_username(org_username)
  o.is_organization.should be_truthy
end

Then /^I should see flash error$/ do
  find(".flash-error").should be_visible
end

Given /^there is an organization "(.*?)"$/ do |org_username|
  FactoryGirl.create(:person, :username => org_username, :is_organization => true)
end

Given /^"(.*?)" is not an organization$/ do |username|
  user = Person.find_by_username(username)
  user.is_organization = false
  user.save!
end

When /^the company-admin verifies employee$/ do
  employee = Person.find_by_email(current_email_address)
  employer = employee.employer
  employer.active = true
  employer.save
end
