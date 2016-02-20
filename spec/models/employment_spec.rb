# == Schema Information
#
# Table name: employments
#
#  id          :integer          not null, primary key
#  company_id  :string(255)
#  employee_id :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE)
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
    @dummy = FactoryGirl.build(:person, :is_organization => false)
    @test_employee = FactoryGirl.build(:person, :is_organization => false, :username => 'XXXXXXX', :organization_name => '')
    @test_employee2 = FactoryGirl.build(:person, :is_organization => false, :username => 'YYYYYYY', :organization_name => '')
    @test_employee3 = FactoryGirl.build(:person, :is_organization => false, :username => 'ZZZZZZZ', :organization_name => '')
    @test_employee4 = FactoryGirl.build(:person, :is_organization => false, :username => 'WWWWWWW', :organization_name => '')
    @test_organization = FactoryGirl.build(:person, :username => 'aaaaaaaaaaa', :organization_name => 'AAA')
    @test_organization2 = FactoryGirl.build(:person, :username => 'bbbbbbbbbbb', :organization_name => 'BBB')
    @test_organization3 = FactoryGirl.build(:person, :username => 'ccccccccccc', :organization_name => 'CCC')
  end

  it "should be valid" do
    expect(@test_employee.class).to eq(Person)
    expect(@test_employee.is_organization).to eq(false)
    expect(@test_employee).not_to be_nil
    expect(@test_employee).to be_valid

    expect(@test_organization.class).to eq(Person)
    expect(@test_organization.is_organization).to eq(true)
    expect(@test_organization).not_to be_nil
  end

  it "should have an id other than 0" do
    expect(@test_employee.id).not_to eq(0)
    expect(@test_organization.id).not_to eq(0)
  end

  it "should create a new employment" do
    lambda {
      Employment.add_employee_to_company(@test_employee2, @test_organization2)
      Employment.add_employee_to_company(@test_employee3, @test_organization2)
    }.should change{Employment.count}.by(2)

    @test_employee2.company.id == @test_organization2.id
    @test_employee3.company.id == @test_organization2.id
    @test_organization2.employees.first.id == @test_employee2.id
    @test_organization2.employees.second.id == @test_employee3.id
    #@test_employee2.companies.first.id == @test_organization2.id
    #@test_employee3.companies.first.id == @test_organization3.id
    #@test_organization2.employees.first.id == @test_employee2.id
    #@test_organization3.employees.first.id == @test_employee3.id
  end


  it "should destroy an employment" do
    Employment.add_employee_to_company(@test_employee4, @test_organization3)
    Employment.remove_employee_from_company(@test_employee4, @test_organization3)

    empl = Employment.find_by_employee_id(@test_employee4.id)
    expect(empl.active).to eq(false)
    expect(@test_organization3.employs?(@test_employee4)).to eq(false)

    #clean up
    Employment.delete_all
  end
end
