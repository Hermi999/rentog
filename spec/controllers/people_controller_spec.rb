require 'spec_helper'

describe PeopleController, type: :controller do

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:person]
  end

  describe "#check_email_availability" do
    before(:each) do
      @request.host = "#{FactoryGirl.create(:community).ident}.lvh.me"
    end

    it "should return available if email not in use" do
      get :check_email_availability,  {:person => {:email => "totally_random_email_not_in_use@example.com"}, :format => :json}
      expect(response.body).to eq("true")
    end
  end

  describe "#check_email_availability" do
    before(:each) do
      @request.host = "#{FactoryGirl.create(:community).ident}.lvh.me"
    end

    it "should return unavailable if email is in use" do
      person = FactoryGirl.create(:person, :emails => [ FactoryGirl.create(:email, :address => "test@example.com")])

      get :check_email_availability,  {:person => {:email_attributes => {:address => "test@example.com"} }, :format => :json}
      expect(response.body).to eq("false")

      Email.create(:person_id => person.id, :address => "test2@example.com")
      get :check_email_availability,  {:person => {:email_attributes => {:address => "test2@example.com"} }, :format => :json}
      expect(response.body).to eq("false")
    end

    it "should return NOT available for user's own adress" do
      person = FactoryGirl.create(:person)
      sign_in person

      Email.create(:person_id => person.id, :address => "test2@example.com")
      get :check_email_availability,  {:person => {:email_attributes => {:address => "test2@example.com"} }, :format => :json}
      expect(response.body).to eq("false")
    end
  end

  describe "#check_email_availability_and_validity" do
    before(:each) do
      @request.host = "#{FactoryGirl.create(:community).ident}.lvh.me"
    end

    it "should return available for user's own adress" do
      person = FactoryGirl.create(:person)
      sign_in person

      Email.create(:person_id => person.id, :address => "test2@example.com")
      get :check_email_availability_and_validity,  {:person => {:email => "test2@example.com"}, :format => :json}
      expect(response.body).to eq("true")
    end
  end

  describe "#check_organization_name_availability" do
    before(:each) do
      @request.host = "#{FactoryGirl.create(:community).ident}.lvh.me"
    end

    it "should return available if organization_name is not in use" do
      get :check_organization_name_availability,  {:person => {:organization_name => "totally_random_organization_not_in_use"}, :format => :json}
      expect(response.body).to eq("true")
    end

    it "should return unavailable if organization_name is in use" do
      person = FactoryGirl.create(:person, organization_name: "R-Bosch")

      get :check_organization_name_availability,  {:person => {organization_name: "r-bOSch"}, :format => :json}
      expect(response.body).to eq("false")
    end
  end

  describe "#update" do
    it "should store the old accepted email as additional email when changing email" do

      # one reason for this is that people can't use one email to create many accounts in email restricted community
      community = FactoryGirl.build(:community, :allowed_emails => "@examplecompany.co")
      @request.host = "#{community.ident}.lvh.me"
      member = FactoryGirl.build(:person, :emails => [ FactoryGirl.build(:email, :address => "one@examplecompany.co")])
      member.communities.push community
      member.save

      person_count = Person.count

      sign_in_for_spec(member)

      request.env["HTTP_REFERER"] = "http://test.host/en/people/#{member.id}"
      put :update, {:person => {:email_attributes => {:address => "something@el.se"}}, :person_id => member.id}

      # remove "signed in" stubs
      request.env['warden'].unstub :authenticate!
      #request.env['warden'].stub(:authenticate!).and_throw(:warden)
      controller.unstub :current_person

      post :create, {:person => {:username => generate_random_username, :password => "test", :email => "one@examplecompany.co", :given_name => "The user who", :family_name => "tries to use taken email", organization_name: "Bosch", signup_as: "organization"}}

      expect(Person.find_by_family_name("tries to use taken email")).to be_nil
      expect(Person.count).to eq(person_count)
      expect(flash[:error].to_s).to include("The email you gave is already in use")

    end
  end

  describe "#create" do

    it "creates an organization" do
      @request.host = "#{FactoryGirl.create(:community).ident}.lvh.me"
      person_count = Person.count
      username = generate_random_username
      post :create, {:person => {:username => username, :password => "test", :email => "#{username}@example.com", :given_name => "", :family_name => "", signup_as: "organization", organization_name: "Simi"}, :community => "test"}
      expect(Person.count).to eq(person_count + 1)
      organization = Person.find_by_username(username)
      expect(organization).not_to be_nil
      expect(organization.is_organization).to eq(true)
      expect(organization.organization_name).not_to be_nil
    end

    it "creates an employee" do
      @request.host = "#{FactoryGirl.create(:community).ident}.lvh.me"
      orga = FactoryGirl.create(:company, organization_name: "ABCD")
      FactoryGirl.create(:email, :person => orga, :address => "abc@xyz.com", :send_notifications => true, :confirmed_at => "2012-05-04 18:17:04")
      employee_count = orga.employees.size
      person_count = Person.count
      username = generate_random_username

      # First try: Should not work, because company does not exist
      post :create, {:person => {:username => username, :password => "testtest", :email => "#{username}@example.com", :given_name => "", :family_name => "", signup_as: "employee", organization_email: "Siem@bosch.at"}, :community => "test"}
      expect(Person.find_by_username(username)).to be_nil
      expect(flash[:error].to_s).to include("The company you've given does not exist")

      # Second try: Should work, because we use a already created company
      post :create, {:person => {:username => username, :password => "testtest", :email => "#{username}@example.com", :given_name => "", :family_name => "", signup_as: "employee", organization_email: "abc@xyz.com"}, :community => "test"}
      expect(Person.find_by_username(username)).not_to be_nil
      expect(Person.count).to eq(person_count + 1)
      employee = Person.find_by_username(username)
      expect(employee).not_to be_nil
      expect(employee.is_organization).to eq(false)
      expect(employee.organization_name).to be_nil
      orga.reload   # Reload orga, so that the employees association gets updatet to the local model object
      expect(orga.employees.size).to eq(employee_count + 1)
      expect(employee.company.organization_name).to eq("ABCD")
    end

    it "doesn't create a new user if submited data is invalid" do
      @request.host = "#{FactoryGirl.create(:community).ident}.lvh.me"
      person_count = Person.count
      username = generate_random_username
      post :create, {:person => {:username => username, :password => "test", :email => "#{username}@example.com", :given_name => "", :family_name => "", :organization_name => "Siemens", :organization_name2 => "Bosch"}, :community => "test"}
      expect(Person.find_by_username(username)).to be_nil
      expect(Person.count).to eq(person_count)
    end

    it "doesn't create an organization for community if email is not allowed" do
      username = generate_random_username
      community = FactoryGirl.build(:community, :allowed_emails => "@examplecompany.co")
      community.save
      @request.host = "#{community.ident}.lvh.me"

      post :create, {:person => {:username => username, :password => "test", :email => "#{username}@example.com", :given_name => "", :family_name => "", :organization_name => "test", :signup_as => "organization"}}

      expect(Person.find_by_username(username)).to be_nil
      expect(flash[:error].to_s).to include("This email is not allowed")
    end
  end

  describe "#destroy" do
    before(:each) do
      @community = FactoryGirl.create(:community)
      @request.host = "#{@community.ident}.lvh.me"
      @person = FactoryGirl.create(:person)
      @community.members << @person
      @id = @person.id
      expect(Person.find_by_id(@id)).not_to be_nil
    end

    it "deletes the person" do
      sign_in_for_spec(@person)

      delete :destroy, {:person_id => @id}
      expect(response.status).to eq(302)

      expect(Person.find_by_id(@id).deleted?).to eql(true)
    end

    it "doesn't delete if not logged in as target person" do
      b = FactoryGirl.create(:person)
      @community.members << b
      sign_in_for_spec(b)

      delete :destroy, {:person_id => @id}
      expect(response.status).to eq(302)

      expect(Person.find_by_id(@id)).not_to be_nil
    end

  end

end
