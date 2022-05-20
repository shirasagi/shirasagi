class Cms::Line::FacilitySearch::Category
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include SS::Relation::File
  include Cms::Addon::Line::Service::PageList
  include Cms::SitePermission
  include Fs::FilePreviewable

  set_permission_name "cms_line_services", :use

  belongs_to :hook, class_name: "Cms::Line::Service::Hook::Base"

  field :name, type: String
  field :summary, type: String
  field :order, type: Integer, default: 0
  field :state, type: String, default: 'public'
  belongs_to_file :image

  validates :hook_id, presence: true
  validates :name, presence: true, length: { maximum: 40 }
  validates :summary, presence: true, length: { maximum: 60 }

  permit_params :name, :summary, :order, :state

  default_scope ->{ order_by order: 1 }

  def state_options
    %w(public closed).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def public?
    state == 'public'
  end

  def file_previewable?(file, user:, member:)
    public?
  end

  class << self
    def and_public
      where(state: "public")
    end

    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
