class Gws::Memo::ListMessage
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Model::Memo::Message
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Memo::Member
  include Gws::Addon::Memo::Body
  # include Gws::Addon::Memo::Priority
  include Gws::Addon::File
  include Gws::Addon::Memo::Quota
  include Gws::Addon::GroupPermission

  attr_accessor :cur_list
  belongs_to :list, class_name: 'Gws::Memo::List'

  before_validation :set_list

  scope :and_list_message, ->{ where(type: 'Gws::Memo::ListMessage') }
  scope :and_list, ->(list) { where(list_id: list.id) }

  alias name subject
  alias reminder_user_ids member_ids

  alias from user
  alias form_id user_id

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
end
