require 'spec_helper'

describe LandingPageController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_redirect
    end
  end

end
