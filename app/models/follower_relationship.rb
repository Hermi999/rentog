# == Schema Information
#
# Table name: follower_relationships
#
#  id                 :integer          not null, primary key
#  person_id          :string(255)      not null
#  follower_id        :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  trust_level        :string(255)      default("trust_admin_and_employees")
#  shipment_necessary :boolean          default(FALSE)
#  payment_necessary  :boolean          default(FALSE)
#
# Indexes
#
#  index_follower_relationships_on_follower_id                (follower_id)
#  index_follower_relationships_on_person_id                  (person_id)
#  index_follower_relationships_on_person_id_and_follower_id  (person_id,follower_id) UNIQUE
#

class FollowerRelationship < ActiveRecord::Base

  attr_accessible :follower_id, :person_id

  belongs_to :person
  belongs_to :follower, :class_name => "Person"

  validates :person_id,
            :presence => true
  validates :follower_id,
            :presence => true,
            :uniqueness => { :scope => :person_id },
            :exclusion => { :in => lambda { |x| [ x.person_id ] } }

  TRUST_LEVEL_TYPES = ["trust_admin_and_employees",
                       "trust_only_admin",
                       "always_confirm"]

  # Ensure that shipment and payment is false, if trust level is not "always_confirm"
  before_save do
    if trust_level == "trust_admin_and_employees" or
       trust_level == "trust_only_admin"
       shipment_necessary = false
       payment_necessary = false
     end
     true
  end

  # Set trust type
  def set_trust_type(type)
    TRUST_LEVEL_TYPES.each do |trust_type|
      if type == trust_type
        self.trust_level = trust_type
      end
    end
  end

  # get relation of company for a specific user
  def self.get_company_user_relation(company, user)
    return "no_relation" if (company.nil? || user.nil?)

    relation = company.inverse_follower_relationships.where(:person_id => user.get_company.id).first

    self.get_company_user_relation(relation)
  end

  def self.get_company_user_relation(relation)
    return "no_relation" if (relation.nil?)

    if relation.person.is_organization
      if relation.trust_level == "trust_admin_and_employees" || relation.trust_level == "trust_only_admin"
        return "full_trust"
      else
        return "trust"
      end
    else
      if relation.trust_level == "trust_admin_and_employees"
        return "full_trust"
      else
        return "trust"
      end
    end

    return "no_relation"
  end
end
