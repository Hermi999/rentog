#  id                   :integer          not null, primary key
#  device_url           :string(255)      not null
#  manufacturer         :string(255)
#  model                :string(255)
#  title                :string(255)
#  category_a           :string(255)
#  category_b           :string(255)
#  price_cents          :integer
#  currency             :string(255)
#  seller               :string(255)
#  provider             :string(255)
#  dev_type             :string(255)
#  condition            :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  seller_country       :string(255)
#  seller_contact       :string(255)
#  renting_price_period :string(255)

ThinkingSphinx::Index.define :price_comparison_device, :with => :active_record do

  #Thinking Sphinx will automatically add the SQL command SET NAMES utf8 as
  # part of the indexing process if the database connection settings have
  # encoding set to utf8. This is default in Rails but with Heroku, we need to
  # be explicit.
  set_property :utf8? => true

  # limit to ....
  #where "listings.open = '1' AND listings.deleted = '0' AND (listings.valid_until IS NULL OR listings.valid_until > now())"

  # fields
  # Fields are the content for search queries – so if you want words tied to a specific document, you better make sure they’re 
  # in a field in your index. They are only string data – you could have numbers and dates and such in your fields, but Sphinx 
  # will only treat them as strings, nothing else.
  indexes title
  indexes manufacturer
  indexes model
  indexes category_a
  indexes category_b

  # attributes
  # Attributes are used for sorting, filtering and grouping your search results. 
  # Their values do not get paid any attention by Sphinx for search terms, though, and they’re limited to the following data types: 
  # integers, floats, datetimes (as Unix timestamps – and thus integers anyway), booleans, and strings. 
  # Take note that string attributes cannot be used in filters, but only for sorting and grouping.
  has id, :as => :device_id
  has price_cents
  has created_at, updated_at

  # properties
  set_property :enable_star => true
  set_property :min_infix_len => 3

  set_property :field_weights => {
    :manufacturer => 10,
    :model        => 8,
    :title        => 3
  }

end
