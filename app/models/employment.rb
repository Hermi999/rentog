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

class Employment < ActiveRecord::Base
  attr_accessible :company_id, :employee_id, :active

  belongs_to :company, :class_name => "Person"
  belongs_to :employee, :class_name => "Person"


  # Add a new employment to a company (=Person)
  # Return false if employee couldn't be added
  def self.add_employee_to_company(employee, company = nil)
    company ||= @current_user

    # Check if relationship already exists. I fyes, then set active to true
    if (employment = company.employments.where(employee_id: employee.id).first)
      employment.active = true
      employment.save
    else
      company.employees << employee
      company.save
    end
  end

  # Remove employment from  a company - only set 'active' to false
  # Also set the employee to inactive, because there is no employee without
  # a company
  # Return false or raised an exception if something went wrong
  def self.remove_employee_from_company(employee, company)
    company ||= @current_user
    @employment = company.employments.where(employee_id: employee.id).first
    #@employment.destroy
    if @employment
      @employment.active = false
      @employment.save
    else
      false
    end
  end
end
