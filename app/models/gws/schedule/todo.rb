class Gws::Schedule::Todo
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Priority
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

  member_include_custom_groups
  permission_include_custom_groups
  readable_setting_include_custom_groups

  field :color, type: String
  field :todo_state, type: String, default: 'unfinished'
  field :deleted, type: DateTime

  permit_params :color, :todo_state, :deleted

  validates :deleted, datetime: true

  after_save ->{ reminders.destroy if deleted.present? }

  def finished?
    todo_state == 'finished'
  end

  scope :without_deleted, ->(date = Time.zone.now) {
    where('$and' => [
      { '$or' => [{ deleted: nil }, { :deleted.gt => date }] }
    ])
  }

  scope :with_only_deleted, ->(date = Time.zone.now) {
    where(:deleted.lt => date)
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

  # override Gws::Addon::Reminder#reminder_url
  def reminder_url(*args)
    # ret = super
    name = reference_model.tr('/', '_') + '_readable_path'
    [name, id: id]
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

  def approval_check_plan?
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

  # alias allowed_for_managers? allowed?
  #
  # def allowed?(action, user, opts = {})
  #   return true if allowed_for_managers?(action, user, opts)
  #   member?(user) || custom_group_member?(user) if action =~ /edit|delete/
  #   false
  # end

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
      todo_state = params[:todo_state].presence rescue nil
      todo_state ||= 'unfinished'

      if todo_state == 'both'
        all
      else
        all.where(todo_state: todo_state)
      end
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

    def member_or_readable(user, opts = {})
      or_cond = Array[member_conditions(user)].flatten.compact
      or_cond += Array[readable_conditions(user, opts)].flatten.compact
      or_cond << allow_condition(:read, user, site: opts[:site]) if opts[:include_role]
      where("$and" => [{ "$or" => or_cond }])
    end
  end
end
