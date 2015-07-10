module Ads::Addon
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :link_action, type: String
      field :link_target, type: String
      field :sort, type: String
      field :with_category, type: String
      field :upper_html, type: String
      field :lower_html, type: String
      permit_params :link_action, :link_target, :sort, :with_category, :upper_html, :lower_html
    end

    public
      def link_action_options
        [
          [I18n.t('ads.options.link_action.cushion'), ''],
          [I18n.t('ads.options.link_action.direct'), 'direct'],
        ]
      end

      def link_target_options
        [
          [I18n.t('ads.options.link_target.self'), ''],
          [I18n.t('ads.options.link_target.blank'), 'blank'],
        ]
      end

      def sort_options
        [
          [I18n.t('ads.options.sort.order'), 'order'],
          [I18n.t('ads.options.sort.random'), 'random'],
        ]
      end

      def with_category_options
        [
          [I18n.t("views.options.state.enabled"), "enabled"],
          [I18n.t("views.options.state.disabled"), "disabled"],
        ]
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
