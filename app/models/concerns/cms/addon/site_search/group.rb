module Cms::Addon::SiteSearch
  module Group
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_groups, class_name: "Cms::Group"
      permit_params st_group_ids: []

      define_method(:st_groups) do
        items = ::Cms::Group.in(id: st_group_ids).to_a
        return items.sort_by { |item| st_group_ids.index(item.id) }
      end
    end

    # def link_target_options
    #   [
    #     [I18n.t('cms.options.link_target.self'), ''],
    #     [I18n.t('cms.options.link_target.blank'), 'blank'],
    #   ]
    # end

    # def search_type_state_options
    #   %w(show hide).collect { |k| [I18n.t("ss.options.state.#{k}"), k == 'show' ? nil : k] }
    # end
  end
end
