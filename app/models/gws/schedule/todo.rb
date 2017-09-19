class Gws::Schedule::Todo
  include SS::Document
  include SS::Scope::ActivationDate
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
  field :activation_date, type: DateTime
  field :expiration_date, type: DateTime

  permit_params :color, :todo_state, :activation_date, :expiration_date

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

  def private_plan?(user)
    return false if readable_custom_group_ids.present?
    return false if readable_group_ids.present?
    readable_member_ids == [user.id]
  end

  def todo_state_name
    self.class.todo_state_names[todo_state.to_sym]
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
