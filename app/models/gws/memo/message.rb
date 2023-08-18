class Gws::Memo::Message
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Model::Memo::Message
  include Gws::Model::Memo::Constructors
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Memo::Restorer
  include Gws::Addon::Memo::Member
  include Gws::Addon::Memo::Body
  include Gws::Addon::Memo::Priority
  include Gws::Addon::File
  include Gws::Addon::Memo::Quota
  #include Gws::Addon::Reminder

  index({ site_id: 1, state: 1, 'user_settings.user_id': 1, 'user_settings.seen_at': 1 })
  index({ site_id: 1, state: 1, 'user_settings.user_id': 1, 'user_settings.path': 1, 'user_settings.seen_at': 1 })
  index({ from_member_name: 1, updated: -1 })
  index({ from_member_name: -1, updated: -1 })
  index({ subject: 1, updated: -1 })
  index({ subject: -1, updated: -1 })
  index({ priority: 1, updated: -1 })
  index({ priority: -1, updated: -1 })
  index({ send_date: 1, updated: -1 })
  index({ send_date: -1, updated: -1 })
  index({ size: 1, updated: -1 })
  index({ size: -1, updated: -1 })

  #after_save :save_reminders, if: ->{ !draft? && unseen?(@cur_user) }

  before_save :apply_filters, if: -> { public? && send_date_was.blank? }

  after_save_files :set_size

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
      filters = Gws::Memo::Filter.site(@cur_site).where(user_id: member_id)
      filters = filters.enabled
      matched_filter = filters.detect { |f| f.match?(self) }
      self.user_settings = user_settings.collect do |user_setting|
        if matched_filter && user_setting['user_id'] == member_id
          path = matched_filter.path
          if path
            user_setting['path'] = path
          end
        end
        user_setting
      end
      self.filtered[member_id.to_s] = Time.zone.now
    end
  end
end
