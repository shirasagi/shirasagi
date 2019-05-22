class Gws::Schedule::TodoComment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Addon::Markdown

  attr_accessor :cur_todo

  belongs_to :todo, class_name: 'Gws::Schedule::Todo'
  field :achievement_rate, type: Integer

  permit_params :achievement_rate

  before_validation :set_todo_id, if: ->{ @cur_todo }

  validates :todo_id, presence: true
  validates :achievement_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_blank: true }
  validates :text, presence: true, if: -> { achievement_rate.blank? }

  scope :and_todo, ->(todo) { where( todo_id: todo.id ) }

  delegate :subscribed_users, to: :todo

  private

  def set_todo_id
    self.todo_id ||= @cur_todo.id
  end
end
