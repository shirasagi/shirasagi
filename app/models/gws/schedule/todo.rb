class Gws::Schedule::Todo
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Colorize
  include Gws::Schedule::Planable
  include Gws::Schedule::Cloneable
  include Gws::Schedule::CalendarFormat
  include Gws::Addon::Schedule::Repeat
  include Gws::Addon::Reminder
  include Gws::Addon::Discussion::Todo
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  field :color, type: String
  field :todo_state, type: String, default: 'unfinished'
  field :deleted, type: DateTime

  permit_params :color, :todo_state, :deleted

  validates :deleted, datetime: true

  after_save ->{ reminders.destroy if deleted.present? }

  def finished?
    todo_state == 'finished'
  end

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end

    if params[:todo_state].present? && params[:todo_state] != 'both'
      criteria = criteria.where todo_state: params[:todo_state]
    end

    criteria
  }

  scope :active, ->(date = Time.zone.now) {
    where('$and' => [
        { '$or' => [{ deleted: nil }, { :deleted.gt => date }] }
    ])
  }

  scope :deleted, -> {
    where(:deleted.exists => true)
  }

  scope :expired, ->(date = Time.zone.now) {
    where('$or' => [
        { :deleted.exists => true , :deleted.lt => date }
    ])
  }

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      all.reorder(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      all.reorder(updated: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('end_at_')
      all.reorder(end_at: key.end_with?('_asc') ? 1 : -1)
    else
      all
    end
  }

  def reminder_user_ids
    member_ids
  end

  def calendar_format(user, site)
    result = super
    result[:title] = I18n.t('gws/schedule/todo.finish_mark') + result[:title] if finished?
    result[:className] = [result[:className], 'fc-event-todo'].flatten
    result
  end

  def private_plan?(user)
    return false if readable_custom_group_ids.present?
    return false if readable_group_ids.present?
    readable_member_ids == [user.id]
  end

  def attendance_check_plan?
    false
  end

  def active?
    now = Time.zone.now
    return false if deleted.present? && deleted < now
    true
  end

  def disable
    now = Time.zone.now
    update_attributes(deleted: now) if deleted.blank? || deleted > now
  end

  def active
    update_attributes(deleted: nil)
  end

  def todo_state_options
    %w(unfinished finished both).map { |v| [I18n.t("gws/schedule/todo.options.todo_state.#{v}"), v] }
  end

  def sort_options
    %w(updated_desc updated_asc created_desc created_asc end_at_desc end_at_asc).map do |k|
      [I18n.t("gws/schedule/todo.options.sort.#{k}"), k]
    end
  end

  def allowed?(action, user, opts = {})
    return true if (action == :read) && owned?(user)
    super(action, user, opts)
  end

  def owned?(user)
    return true if member?(user)
    return true if (self.group_ids & user.group_ids).present?
    return true if user_ids.to_a.include?(user.id)
    return true if custom_groups.any? { |m| m.member_ids.include?(user.id) }
    false
  end

  class << self
    def search(params)
      criteria = all.search_keyword(params)
      criteria = criteria.search_todo_state(params)
      criteria = criteria.search_start_end(params)
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_todo_state(params)
      return all.where(todo_state: "unfinished") if params.blank? || params[:todo_state].blank?
      return all if params[:todo_state] == "both"
      all.where(todo_state: params[:todo_state])
    end

    def search_start_end(params)
      return all if params.blank?

      criteria = all
      if params[:start].present?
        criteria = criteria.gte(end_at: params[:start])
      end
      if params[:end].present?
        criteria = criteria.lte(start_at: params[:end])
      end
      criteria
    end

    def allow_condition(action, user, opts = {})
      cond = [
        # { :readable_group_ids.in => user.group_ids.to_a },
        # { readable_member_ids: user.id },
        { user_ids: user.id },
        { member_ids: user.id }
      ]

      if member_include_custom_groups?
        cond << { :member_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      end

      # if readable_setting_included_custom_groups?
      #   cond << { :readable_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      # end

      {'$or' => cond }
    end
  end
end

