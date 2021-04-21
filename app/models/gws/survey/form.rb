class Gws::Survey::Form
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Contributor
  include Gws::Addon::Survey::ColumnSetting
  include Gws::Addon::Survey::Category
  include Gws::Addon::Survey::FilesRef
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Survey::AnswerState
  include Gws::Survey::Notification

  readable_setting_include_custom_groups
  permission_include_custom_groups

  field :name, type: String
  field :description, type: String
  field :order, type: Integer
  field :state, type: String, default: 'closed'
  field :memo, type: String

  field :due_date, type: DateTime
  field :release_date, type: DateTime
  field :close_date, type: DateTime

  field :anonymous_state, type: String, default: 'disabled'
  field :file_state, type: String
  field :file_edit_state, type: String, default: 'enabled'

  permit_params :name, :description, :order, :memo, :due_date, :release_date, :close_date
  permit_params :file_edit_state

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :due_date, presence: true, datetime: true
  validates :anonymous_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
  validates :file_state, inclusion: { in: %w(closed public), allow_blank: true }
  validates :file_edit_state, inclusion: { in: %w(disabled enabled enabled_until_due_date), allow_blank: true }

  scope :and_public, ->(date = Time.zone.now) {
    date = date.dup
    where("$and" => [
      { state: "public" },
      { "$or" => [ { release_date: nil }, { :release_date.lte => date } ] },
      { "$or" => [ { close_date: nil }, { :close_date.gt => date } ] },
    ])
  }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_category(params)
      criteria = criteria.search_categories(params)
      criteria = criteria.search_answer_state(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, :description)
    end

    def search_category(params)
      return all if params.blank? || params[:category_id].blank?

      all.where(category_ids: params[:category_id].to_i)
    end

    def search_categories(params)
      category_ids = [ params[:category_ids].presence ].flatten.compact.select(&:present?)
      return all if category_ids.blank?

      category_ids = category_ids.map(&:to_i)
      all.in(category_ids: category_ids)
    end

    def search_answer_state(params)
      return all if params.blank? || params[:answered_state].blank?

      case params[:answered_state]
      when 'answered'
        all.and_answered(params[:user])
      when 'unanswered'
        all.and_unanswered(params[:user])
      when 'both'
        all
      else
        none
      end
    end
  end

  def state_options
    %w(closed public).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def closed?
    !public?
  end

  def public?(now = Time.zone.now)
    return false if state != 'public'
    return false if release_date && release_date > now
    return false if close_date && close_date <= now

    true
  end

  def anonymous_state_options
    %w(disabled enabled).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def anonymous?
    anonymous_state == 'enabled'
  end

  def file_state_options
    %w(closed public).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def file_closed?
    !file_public?
  end

  def file_public?
    file_state == 'public'
  end

  def file_edit_state_options
    %w(disabled enabled enabled_until_due_date).map { |m| [I18n.t("gws/survey.options.file_edit_state.#{m}"), m] }
  end

  def file_editable?(now = nil)
    return false if file_edit_state == 'disabled'

    if file_edit_state == 'enabled_until_due_date'
      now ||= Time.zone.now
      return false if now >= due_date
    end

    true
  end

  def new_flag?
    (release_date.presence || created) > Time.zone.now - site.survey_new_days.day
  end

  def new_clone(opts = {})
    dest_site = opts[:site] || site
    dest_user = opts[:user] || user
    dest_name = opts[:name] || name
    dest_anonymous_state = opts[:anonymous_state]
    dest_file_state = opts[:file_state]

    dest = self.class.new
    dest.site = dest_site
    dest.user = dest_user
    dest.name = dest_name
    dest.description = description
    dest.file_edit_state = file_edit_state
    dest.due_date = due_date
    dest.release_date = release_date
    dest.close_date = close_date
    dest.memo = memo
    dest.category_ids = category_ids
    dest.contributor_model = dest_user.class.to_s
    dest.contributor_id = dest_user.id
    dest.contributor_name = dest_user.long_name
    dest.readable_setting_range = readable_setting_range
    dest.readable_custom_group_ids = readable_custom_group_ids
    dest.readable_group_ids = readable_group_ids
    dest.readable_member_ids = readable_member_ids
    dest.custom_group_ids = custom_group_ids
    dest.group_ids = group_ids
    dest.user_ids = user_ids
    dest.permission_level = permission_level
    dest.state = "closed"

    dest.anonymous_state = dest_anonymous_state if dest_anonymous_state.present?
    dest.file_state = dest_file_state if dest_file_state.present?

    return dest unless dest.valid?

    dest_columns = self.columns.map do |column|
      attr = column.attributes.except("_id", "_type", "form_id", "site_id", "created", "updated")
      dest_column = column.class.new attr
      dest_column.site = dest_site
      dest_column.form = dest
      dest_column.save
      dest_column
    end
    dest.columns = dest_columns

    dest
  end
end
