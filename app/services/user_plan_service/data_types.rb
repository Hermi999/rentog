module UserPlanService::DataTypes
  # User Plan levels
  LEVELS = {
    :free => :a,
    :basic => :b,
    :premium => :c,
    :ultimate => :d
  }

  FEATURES = {
    # How many employees a company can add
    :company_employees => { a: 30, b: 60, c: 120, d: 1000 },

    # How many non marketplace devices a company can create
    :company_non_market_listings => { a: 30, b: 60, c: 120, d: 1000 },

    # How many other companies a company can trust
    :company_trusted_users => { a: 0, b: 1, c: 10, d: 100},

    # How many listing attachments a company can add to each listing
    :listing_attachments => { a: 1, b: 5, c: 10, d: 30 },

    # How many attributes a company can add to its listings
    :listing_optional_attributes => { a: 5, b: 10, c: 50, d: 100 }
  }
end
