module Lsorg::Addon
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      belongs_to :page_group, class_name: "Cms::Group"
      permit_params :page_group_id

      self.use_loop_formats = %i(liquid)
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

    def condition_hash(options = {})
      if page_group.nil?
        return { id: -1 }
      end

      if conditions.present?
        # 指定されたフォルダー内のページが対象
        cond1 = super
      else
        # サイト内の全ページが対象
        default_site = options[:site] || @cur_site || self.site
        cond1 = { site_id: default_site.id }
      end

      cond2 = { "$or" => [
        { contact_group_id: { "$in" => [page_group_id] } },
        { contact_sub_group_ids: { "$in" => [page_group_id] } }
      ]}

      { "$and" => [cond1, cond2] }
    end
  end
end
