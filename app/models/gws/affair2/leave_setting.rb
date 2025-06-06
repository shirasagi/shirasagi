class Gws::Affair2::LeaveSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_affair2_admin_settings", :use

  seqid :id
  field :name, type: String
  field :order, type: Integer
  embeds_ids :special_leave, class_name: "Gws::Affair2::SpecialLeave"

  permit_params :name, :order
  permit_params special_leave_ids: []

  validates :name, presence: true, length: { maximum: 80 }

  default_scope -> { order_by(order: 1) }

  def leave_type_options
    self.class.selectable_leave_type_options
  end

  def special_leave_options
    special_leave.to_a.map { |item| [item.name, item.id] }
  end

  class << self
    def leave_type_options
      I18n.t("gws/affair2.options.leave_type").map { |k, v| [v, k] }
    end

    def selectable_leave_type_options
      %w(paid sick1 sick2 nursing_care special).map do |k|
        [ I18n.t("gws/affair2.options.leave_type.#{k}"), k ]
      end
    end

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
