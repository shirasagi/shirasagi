module Cms::Addon
  module PageGroupList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      self.use_no_items_display = false
      self.use_substitute_html = false
      self.use_loop_formats = %i(shirasagi)

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
      %w(name filename created updated_desc released_desc order order_desc).map do |k|
        [
          I18n.t("cms.sort_options.#{k}.title"),
          k.sub("_desc", " -1"),
          "data-description" => I18n.t("cms.sort_options.#{k}.description", default: nil)
        ]
      end
    end

    def sort_hash
      return { released: -1 } if sort.blank?
      { sort.sub(/ .*/, "") => (/-1$/.match?(sort) ? -1 : 1) }
    end
  end
end
