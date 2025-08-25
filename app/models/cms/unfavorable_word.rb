class Cms::UnfavorableWord
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_tools", :use

  # field separator
  FS = %w(, 、 ，).freeze

  field :name, type: String
  field :body, type: String
  field :state, type: String

  permit_params :name, :body, :state

  validates :name, presence: true
  validates :body, presence: true
  validates :state, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :body
      end

      criteria
    end

    def and_enabled
      all.where(state: 'enabled')
    end
  end

  def state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end
end
