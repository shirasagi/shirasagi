class Gws::Memo::Comment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include SS::Addon::Markdown

  set_permission_name 'private_gws_memo_messages', :edit

  attr_accessor :cur_message

  belongs_to :message, class_name: 'Gws::Memo::Message'

  validates :message_id, presence: true
  validates :text, presence: true

  before_validation :set_message_id, if: ->{ @cur_message }
  scope :message, ->(message) { where( message_id: message.id ) }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MemoCommentJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MemoCommentJob.callback

  def set_message_id
    self.message_id ||= @cur_message.id
  end
end
