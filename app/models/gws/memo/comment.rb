class Gws::Memo::Comment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Addon::Markdown
  include Gws::Addon::GroupPermission

  set_permission_name 'gws_memo_messages'

  attr_accessor :cur_message

  belongs_to :message, class_name: 'Gws::Memo::Message'
  validates :message_id, presence: true
  before_validation :set_message_id, if: ->{ @cur_message }
  scope :message, ->(message) { where( message_id: message.id ) }

  def set_message_id
    self.message_id ||= @cur_message.id
  end
end
