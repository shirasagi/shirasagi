module Ads::Addon
  module BannerSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 200

    included do
      field :sort, type: String
      permit_params :sort
    end

    public
      def sort_options
        [ ["指定順", "order"], ["ランダム", "random"] ]
      end

      def sort_hash
        if sort == "random"
          { random: 1 }
        else
          { order: 1 }
        end
      end
  end
end
