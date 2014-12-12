module Ads::Addon
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :sort, type: String
      field :upper_html, type: String
      field :lower_html, type: String
      permit_params :sort, :upper_html, :lower_html
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
