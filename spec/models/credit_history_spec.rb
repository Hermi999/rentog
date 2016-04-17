# == Schema Information
#
# Table name: credit_histories
#
#  id            :integer          not null, primary key
#  person_id     :string(255)
#  other_user_id :string(255)
#  type          :string(255)
#  credits       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

RSpec.describe CreditHistory, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
