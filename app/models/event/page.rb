class Event::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Gravatar::Addon::Gravatar
  include Cms::Addon::Body
  include Cms::Addon::File
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Event::Addon::Body
  include Cms::Addon::AdditionalInfo
  include Event::Addon::Date
  include Map::Addon::Page
  include Cms::Addon::RelatedPage
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Event::Addon::Csv::Page

  set_permission_name "event_pages"

  default_scope ->{ where(route: "event/page") }

  scope :search_by_date, ->(dates){ where(:event_dates.in => dates) }
  scope :gt_dates, ->(start_date){ where(:event_dates.gte => start_date) }
  scope :lt_dates, ->(close_date){ where(:event_dates.lte => close_date) }
  scope :search_by_categories, ->(criteria, cate_ids){
    cate = cate_ids.map { |e| e.to_i if e.present? }
    con = []
    cate.each do |c|
      con << {:category_ids => c }
    end
    criteria = criteria.where({ :$or => con })
    criteria
  }

  class << self
    def search(params)

      criteria = super
      return criteria if params.blank?
      if params[:dates].present?
        criteria = criteria.search_by_date(params[:dates])
      end

      if params[:start_date].present?
        criteria = criteria.gt_dates(params[:start_date])
      end

      if params[:close_date].present?
        criteria = criteria.lt_dates(params[:close_date])
      end

      if params[:categories].present?
        criteria = search_by_categories(criteria, params[:categories])
      end
      criteria
    end
  end
end
