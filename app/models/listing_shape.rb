# == Schema Information
#
# Table name: listing_shapes
#
#  id                     :integer          not null, primary key
#  community_id           :integer          not null
#  transaction_process_id :integer          not null
#  price_enabled          :boolean          not null
#  shipping_enabled       :boolean          not null
#  name                   :string(255)      not null
#  name_tr_key            :string(255)      not null
#  action_button_tr_key   :string(255)      not null
#  sort_priority          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  deleted                :boolean          default(FALSE)
#
# Indexes
#
#  index_listing_shapes_on_community_id  (community_id)
#  index_listing_shapes_on_name          (name)
#  multicol_index                        (community_id,deleted,sort_priority)
#

class ListingShape < ActiveRecord::Base
  attr_accessible(
    :community_id,
    :transaction_process_id,
    :price_enabled,
    :shipping_enabled,
    :name,
    :sort_priority,
    :name_tr_key,
    :action_button_tr_key,
    :price_quantity_placeholder,
    :deleted
  )

  has_and_belongs_to_many :categories, -> { order("sort_priority") }, join_table: "category_listing_shapes"
  has_many :listing_units

  # wah
  has_many :listingshape_custom_fields, :dependent => :destroy
  has_many :custom_fields, -> { order("sort_priority") }, :through => :listingshape_custom_fields

  def self.columns
    super.reject { |c| c.name == "transaction_type_id" || c.name == "price_quantity_placeholder" }
  end


  def get_standardized_listingshape_name
    # If private listing, then check availability
    if name.nil? || (name.downcase.include? "privat")
      "private"

    # otherweise check ListingShape name
    else
      if name.downcase.include? "vermieten" or
         name.downcase.include? "rent"
        "rent"
      elsif name.downcase.include? "kaufen" or
            name.downcase.include? "buy" or
            name.downcase.include? "sell"
        "sell"
      elsif name.downcase.include? "vermarkten" or
            name.downcase.include? "ad"
        "ad"
      else
        name.downcase
      end
    end
  end

  def self.get_shape_from_name(name)
    name =
      if name.nil? || (name.downcase.include? "privat") || (name.downcase.include? "trusted")
        "name LIKE '%private%'"
      elsif name.downcase.include? "vermieten" or
         name.downcase.include? "rent"
        "name LIKE '%rent%' OR name LIKE '%vermieten%'"
      elsif name.downcase.include? "kaufen" or
            name.downcase.include? "buy" or
            name.downcase.include? "sell"
        "name LIKE '%buy%' OR name LIKE '%sell%' OR name LIKE '%kaufen%'"
      elsif name.downcase.include? "vermarkten" or
            name.downcase.include? "ad"
        "name LIKE '%vermarkten%' OR name LIKE '%ad%'"
      else
        return nil
        ""
      end

    ListingShape.where("deleted = 0 AND (#{name})")[0]
  end
end
