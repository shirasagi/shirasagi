class Gws::Affair2::DutyNotice
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_affair2_admin_settings", :use

  seqid :id

  field :name, type: String
  field :notice_type, type: String
  field :threshold_hour, type: Integer
  field :body, type: String

  permit_params :name
  permit_params :notice_type
  permit_params :threshold_hour
  permit_params :body

  validates :name, presence: true
  validates :notice_type, presence: true
  validates :threshold_hour, presence: true
  validates :body, presence: true

  def notice_type_options
    I18n.t("gws/affair2.options.notice_type").map { |k, v| [v, k] }
  end

  class << self
    def search(params)
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
  end
end
