class Gws::Memo::ListMessage
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Model::Memo::Message
  include Gws::Referenceable
  # DO NOT INCLUDE Gws::Reference::User module
  # because gws/memo/filter match hidden user accidentally if Gws::Reference::User module was included.
  # include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Memo::Member
  include Gws::Addon::Memo::Body
  include Gws::Addon::File
  include Gws::Addon::Memo::Quota
  include Gws::Addon::GroupPermission

  attr_accessor :cur_user, :cur_list, :in_append_signature
  belongs_to :list, class_name: 'Gws::Memo::List'

  before_validation :set_list

  validates :list_id, presence: true

  before_save :append_signature, if: ->{ @in_append_signature }

  scope :and_list_message, ->{ where(type: 'Gws::Memo::ListMessage') }
  scope :and_list, ->(list) { where(list_id: list.id) }

  alias name subject
  alias reminder_user_ids member_ids

  # alias from user
  # alias form_id user_id

  alias to to_members
  alias to_ids to_member_ids

  # # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback

  private

  def set_list
    return if @cur_list.blank?
    self.list = @cur_list
  end

  def append_signature
    sign = list.signature.presence
    if sign
      self.text += "\n\n#{sign}" if self.text.present?
      self.html += "<p></p>" + h(sign.to_s).gsub(/\r\n|\n/, '<br />') if self.html.present?
    end
  end
end
