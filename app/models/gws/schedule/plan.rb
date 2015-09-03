class Gws::Schedule::Plan
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Planable
  include Gws::Addon::GroupPermission

  #TODO: 繰り返しのデータの持ち方については、要検討
  belongs_to :repeat, class_name: 'Gws::Schedule::PlanRepeat'

  has_and_belongs_to_many :users, class_name: 'Gws::User' # rubocop:disable all

  #TODO: 設備予約
  #TODO: 公開範囲
  #TODO: 編集権限

  #TODO: 繰り返しのバリデーションを書く
  #TODO: 設備予約のバリデーションを書く
  #TODO: 公開範囲のバリデーションを書く
  #TODO: 編集権限のバリデーションを書く

  scope :member, ->(user) { where member_ids: user.id }
  scope :facility, ->(item) { where facility_ids: item.id }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria = criteria.where :start_at.gte => params[:start] if params[:start].present?
    criteria = criteria.where :end_at.lte => params[:end] if params[:end].present?
    criteria
  }

  public
    def allday_options
      [
        [I18n.t("gws_schedule.options.allday.allday"), "allday"]
      ]
    end

    def allday?
      allday == "allday"
    end

    def category_options
      site = self.site || @cur_site
      Gws::Schedule::Category.site(site).map { |c| [c.name, c.id] }
    end
end
