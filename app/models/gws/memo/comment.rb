class Gws::Memo::Comment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include SS::Addon::Markdown

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
# module Gws::Reference
#   module Schedule
#     extend ActiveSupport::Concern
#     extend SS::Translation
#
#     attr_accessor :cur_schedule
#
#     included do
#       belongs_to :schedule, class_name: 'Gws::Schedule::Plan'
#
#       validates :schedule_id, presence: true
#       before_validation :set_schedule_id, if: ->{ @cur_schedule }
#
#       scope :schedule, ->(schedule) { where( schedule_id: schedule.id ) }
#     end
#
#     private
#
#     def set_schedule_id
#       self.schedule_id ||= @cur_schedule.id
#     end
#   end
# end