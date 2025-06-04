class Gws::Affair2::SpecialHoliday
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_affair2_admin_settings", :use

  seqid :id
  field :name, type: String
  field :date, type: DateTime

  permit_params :date

  validates :date, presence: true

  before_save :set_name

  default_scope -> { order_by(date: 1) }

  def set_name
    self.name = I18n.l(date.to_date, format: :full)
  end

  class << self
    def and_year(year)
      start_date = Time.zone.local(year, 1, 1)
      close_date = start_date.end_of_year
      self.and([
        { "date" => { "$gte" => start_date } },
        { "date" => { "$lte" => close_date } }
      ])
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
