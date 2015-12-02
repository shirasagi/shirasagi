module Cms::Addon
  module PageGroupList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      embeds_ids :condition_groups, class_name: "SS::Group"
      permit_params condition_group_ids: []
    end

    public
      def condition_hash
        { :group_ids.in => condition_groups.map(&:id) }
      end

      def sort_options
        [
          [I18n.t('cms.options.sort.name'), 'name'],
          [I18n.t('cms.options.sort.filename'), 'filename'],
          [I18n.t('cms.options.sort.created'), 'created'],
          [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
          [I18n.t('cms.options.sort.released_1'), 'released -1'],
          [I18n.t('cms.options.sort.order'), 'order'],
        ]
      end

      def sort_hash
        return { released: -1 } if sort.blank?
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
  end
end
