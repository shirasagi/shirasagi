class Gws::Affair2::DutySetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair2::DutySetting::Worktime
  include Gws::Addon::Affair2::DutySetting::Workday
  include Gws::Addon::Affair2::DutySetting::Leave
  include Gws::Addon::Affair2::DutySetting::Notice
  include Gws::SitePermission

  set_permission_name "gws_affair2_admin_settings", :use

  seqid :id
  field :name, type: String
  field :employee_type, type: String
  field :worktime_type, type: String
  field :order, type: Integer

  permit_params :name, :employee_type, :worktime_type, :order

  validates :name, presence: true, length: { maximum: 80 }
  validates :employee_type, presence: true
  validates :worktime_type, presence: true

  default_scope -> { order_by(order: 1, name: 1) }

  def employee_type_options
    I18n.t("gws/affair2.options.employee_type").map { |k, v| [v, k] }
  end

  def worktime_type_options
    I18n.t("gws/affair2.options.worktime_type").map { |k, v| [v, k] }
  end

  def worktime_constant?
    worktime_type == "constant"
  end

  def worktime_variable?
    worktime_type == "variable"
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
