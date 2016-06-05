module UserPlanService
  class Api

    def initialize()
    end

    # sets the plan level of all featues of the user - this should be the standard method to be called.
    # Because most of the time the user should be a "premium", "ultimate", "free" user and should not have
    # individual plans for the different features.
    # for example:
    #   - user_plan = "free"
    #   - user_plan_features = "{\"company_employees\":\"free\",\"company_non_market_listings\":\"free\", ... }
    #
    #   feature and plan_level has to be passed as symbols
    def set_plan_and_feature_plan_levels(user, plan_level)
      set_plan_level(user, plan_level)
      set_features_plan_levels(user, plan_level)
    end


    # set the plan level of a given feature of the user
    # This is called from the controller if only a specific feature should be
    # set to a higher or lower plan level. In this case the overall user_plan
    # is set to "custom"
    def set_feature_plan_level(user, feature, plan_level)
      # Old user in DB. Set level to :free
      if user.user_plan_features == nil
        set_features_plan_levels(user, :free)
      end

      # get an hash with the current features and their set plans
      old_user_plan_features = JSON.parse user.user_plan_features
      # update the plan of the given feature
      old_user_plan_features[feature.to_s] = plan_level.to_s
      # update the value in the model
      user.user_plan_features = old_user_plan_features.to_json
      # update also the user_plan attribute to "custom"
      user.update_attribute(:user_plan, "custom")

      user.save unless user.new_record?
    end

    # return the current overall user plan level
    def get_plan_level(user)
      user.user_plan.to_sym
    end

    # return all user plan feature levels as hash
    def get_plan_features_levels(user)
      # Old user in DB. Set level to :free
      if user.user_plan_features == nil
        set_features_plan_levels(user, :free)
      end

      names = JSON.parse user.user_plan_features
      names.each do |name|
        names[name[0]] = {name: name[1], value: UserPlanService::DataTypes::FEATURES[name[0].to_sym][UserPlanService::DataTypes::LEVELS[name[1].to_sym]]}
      end
      names
    end

    # returns the current plan infos of a given user in relation to a given feature
    def get_plan_feature_level(user, feature)
      temp = get_plan_features_levels(user)
      level = temp[feature.to_s]
    end


    private

      # set the overall user plan level
      def set_plan_level(user, plan_level)
        user.user_plan = plan_level.to_s
      end

      # set the plan level of all features of the user to a certain value
      def set_features_plan_levels(user, plan_level)
        val = {}
        UserPlanService::DataTypes::FEATURES.each do |feature|
          val[feature[0]] = plan_level #feature[1][UserPlanService::DataTypes::LEVELS[plan_level]]
        end
        user.user_plan_features = val.to_json
        user.save unless user.new_record?
      end

  end
end
