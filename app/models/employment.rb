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

class Employment < ActiveRecord::Base
  attr_accessible :company_id, :employee_id

  belongs_to :company, :class_name => "Person"
  belongs_to :employee, :class_name => "Person"


  # Add a new employment to a company (=Person)
  # Return false if employee couldn't be added
  def self.add_employee_to_company(employee, company = nil)
    company ||= @current_user
    company.employees << employee
    company.save
  end

  # Remove employment from  a company
  # Return false or raised an exception if something went wrong
  def self.remove_employee_from_company(employment_id, company = nil)
    company ||= @current_user
    @employment = company.employments.find(employment_id)
    @employment.destroy
  end
end
