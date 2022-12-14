class Gws::Affair::DutyCalendar
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::DutyHour
  include Gws::Addon::Affair::Holiday
  include Gws::Addon::Affair::Flextime
  include Gws::Addon::Affair::DutyNotice
  include Gws::Addon::Member
  include Gws::SitePermission

  set_permission_name "gws_affair_duty_settings", :edit

  member_ids_optional

  seqid :id
  field :name, type: String

  permit_params :name

  validates :name, presence: true

  def shift_exists?(date)
    false
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
