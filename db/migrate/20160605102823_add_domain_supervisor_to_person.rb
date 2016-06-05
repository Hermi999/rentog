class AddDomainSupervisorToPerson < ActiveRecord::Migration
  def change
    add_column :people, :is_domain_supervisor, :boolean, default: false
  end
end
