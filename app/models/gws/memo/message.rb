class Gws::Memo::Message
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Model::Memo::Message
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::Memo::Member
  include Gws::Addon::Memo::Body
  include Gws::Addon::Memo::Priority
  include Gws::Addon::File
  include Gws::Addon::Memo::Quota
  #include Gws::Addon::Memo::Comments
  #include Gws::Addon::Reminder

  #after_save :save_reminders, if: ->{ !draft? && unseen?(@cur_user) }

  before_save :apply_filters, if: -> { public? && send_date_was.blank? }

  alias name subject
  alias reminder_user_ids member_ids

  alias from user
  alias form_id user_id

  alias to to_members
  alias to_ids to_member_ids

  set_permission_name 'private_gws_memo_messages', :edit

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback

  private

  def apply_filters
    return unless @cur_site

    member_ids.each do |member_id|
      next if filtered[member_id.to_s]
      matched_filter = Gws::Memo::Filter.site(@cur_site).where(user_id: member_id).enabled.detect{ |f| f.match?(self) }
      self.path[member_id.to_s] = matched_filter.path if matched_filter
      self.filtered[member_id.to_s] = Time.zone.now
    end
  end
end
