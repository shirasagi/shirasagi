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
      [I18n.t("views.options.state.public"), "public"],
      [I18n.t("views.options.state.closed"), "closed"],
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
        h[:source_cleaner][idx]["replaced_value"] = item.replaced_value
      end

      h
    end
  end
end
