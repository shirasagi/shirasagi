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

  scope :and_list_message, ->{ where(type: 'Gws::Memo::ListMessage') }

  alias name subject
  alias reminder_user_ids member_ids

  alias from user
  alias form_id user_id

  alias to to_members
  alias to_ids to_member_ids

  # # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback
end
