module FooterSteps
end
World(FooterSteps)


When(/^I follow "(.*)" within the footer$/) do |label|
  steps %Q{
    When I follow "#{label}" within ".footer-wrapper"
  }
end

