class Gws::Schedule::Todo
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Colorize
  include Gws::Schedule::Planable
  include Gws::Schedule::CalendarFormat
  include Gws::Addon::Schedule::Repeat
  include Gws::Addon::Reminder
  include SS::Addon::Markdown
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  field :color, type: String
  field :todo_state, type: String, default: 'unfinished'
  field :deleted, type: DateTime

  permit_params :color, :todo_state, :deleted

  validates :deleted, datetime: true

  def finished?
    todo_state == 'finished'
  end

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end

    if params[:todo_state].present?
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

  def calendar_format(user, site)
    result = super
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

  def todo_state_name
    self.class.todo_state_names[todo_state.to_sym]
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

  class << self
    def todo_state_names
      @@_todo_state_names ||= I18n.t('gws/schedule/todo.options.todo_state')
    end

    def todo_state_options
      @@_todo_state_options ||= todo_state_names.map(&:reverse)
    end
  end
end
