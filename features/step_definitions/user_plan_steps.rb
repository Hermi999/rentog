Given /^I am a "([^"]*)" user$/ do |type|
  user_plan = UserPlanService::Api.new
  user_plan.set_plan_and_feature_plan_levels(@current_user, type.to_sym)
end


Given /^"([^"]*)" is a "([^"]*)" user$/ do |username, type|
  user = Person.find(username)
  user_plan = UserPlanService::Api.new
  user_plan.set_plan_and_feature_plan_levels(user, type.to_sym)
end
