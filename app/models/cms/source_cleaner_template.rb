class Cms::SourceCleanerTemplate
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Cms::Addon::SourceCleaner

  set_permission_name "cms_tools", :use

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :state, type: String, default: "public"

  permit_params :name, :order, :state
  validates :name, presence: true, length: { maximum: 40 }

  default_scope -> { order_by(order: 1, name: 1) }
  scope :and_public, ->{ where state: "public" }

  def state_options
    [
      [I18n.t("ss.options.state.public"), "public"],
      [I18n.t("ss.options.state.closed"), "closed"],
    ]
  end

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end

    def to_config(opts = {})
      h = {}
      h[:source_cleaner] = {}

      self.all.each_with_index do |item, idx|
        h[:source_cleaner][idx] = {}
        h[:source_cleaner][idx]["target_type"] = item.target_type
        h[:source_cleaner][idx]["target_value"] = item.target_value
        h[:source_cleaner][idx]["action_type"] = item.action_type
        h[:source_cleaner][idx]["replace_source"] = item.replace_source
        h[:source_cleaner][idx]["replaced_value"] = item.replaced_value
      end

      if opts[:site].present?
        h[:source_cleaner_site_setting] = {}
        h[:source_cleaner_site_setting]['unwrap_tag_state'] = opts[:site].source_cleaner_unwrap_tag_state
        h[:source_cleaner_site_setting]['remove_tag_state'] = opts[:site].source_cleaner_remove_tag_state
        h[:source_cleaner_site_setting]['remove_class_state'] = opts[:site].source_cleaner_remove_class_state
      end

      h
    end
  end
end
