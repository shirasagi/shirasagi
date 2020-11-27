module Cms::Addon
  module PageGroupList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      embeds_ids :condition_groups, class_name: "SS::Group"
      permit_params condition_group_ids: []
    end

    def condition_hash(options = {})
      if conditions.present?
        # 指定されたフォルダー内のページが対象
        cond = super
      else
        # サイト内の全ページが対象
        default_site = options[:site] || @cur_site || self.site
        cond = { site_id: default_site.id }
      end

      cond.merge(:group_ids.in => condition_groups.active.pluck(:id))
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
      { sort.sub(/ .*/, "") => (/-1$/.match?(sort) ? -1 : 1) }
    end
  end
end
