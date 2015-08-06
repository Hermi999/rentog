# == Schema Information
#
# Table name: employments
#
#  id          :integer          not null, primary key
#  company_id  :string(255)
#  employee_id :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_employments_on_company_id   (company_id)
#  index_employments_on_employee_id  (employee_id)
#

require 'spec_helper'

describe Employment do
  before(:all) do
    #These will be created only once for the whole example group
    @dummy = FactoryGirl.build(:employee, :is_organization => false)
    @test_employee = FactoryGirl.build(:employee, :is_organization => false, :username => 'XXXXXXX', :organization_name => '')
    @test_employee2 = FactoryGirl.build(:employee, :is_organization => false, :username => 'YYYYYYY', :organization_name => '')
    @test_organization = FactoryGirl.build(:organization, :username => 'aaaaaaaaaaa', :organization_name => 'AAA')
    @test_organization2 = FactoryGirl.build(:organization, :username => 'bbbbbbbbbbb', :organization_name => 'BBB')
  end

  it "should be valid" do
    @test_employee.class.should == Person
    @test_employee.is_organization == true
    @test_employee.should_not be_nil
    @test_employee.should be_valid

    @test_organization.class.should == Person
    @test_organization.is_organization == false
    @test_organization.should_not be_nil
    #@test_organization.should be_valid
  end

  it "should have an id other than 0" do
    @test_employee.id.should_not == 0
    @test_organization.id.should_not == 0
  end

  describe "#create and destroy" do
    it "should create a new employment" do
      lambda {
        Employment.add_employee_to_company(@test_employee, @test_organization)
        Employment.add_employee_to_company(@test_employee2, @test_organization2)
      }.should change{Employment.count}.by(2)

      @test_employee.company.id == @test_organization.id
      @test_employee2.company.id == @test_organization2.id
      @test_organization.employees.first.id == @test_employee.id
      @test_organization2.employees.first.id == @test_employee2.id
      #@test_employee.companies.first.id == @test_organization.id
      #@test_employee2.companies.first.id == @test_organization2.id
      #@test_organization.employees.first.id == @test_employee.id
      #@test_organization2.employees.first.id == @test_employee2.id
    end


    it "should destroy an employment" do
      Employment.add_employee_to_company(@test_employee, @test_organization)
      empl = Employment.first
      lambda {
        Employment.remove_employee_from_company(empl.id, @test_organization)
      }.should change{Employment.count}.by(-1)

      # There shouldn't be any entries in the Employment table
      #@test_employee.companies == []
      @test_employee.company == nil
      @test_organization.employees == []
      Employment.all == []
    end
  end
end
