class Gws::Report::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Reminder
  include Gws::Addon::Report::CustomForm
  include Gws::Addon::Member
  include Gws::Addon::Schedules
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  member_ids_optional

  seqid :id
  field :state, type: String, default: 'closed'
  field :name, type: String

  permit_params :name

  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :name, presence: true, length: { maximum: 80 }
  after_save :send_notification_mail

  scope :and_public, -> { where(state: 'public') }
  scope :and_closed, -> { where(state: 'closed') }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_state(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_state(params)
      return all if params[:state].blank? || params[:cur_site].blank? || params[:cur_user].blank?

      cur_site = params[:cur_site]
      cur_user = params[:cur_user]
      case params[:state]
      when 'inbox'
        all.and_public.member(cur_user)
      when 'sent'
        all.and_public.user(cur_user)
      when 'closed'
        all.and_closed.user(cur_user)
      else
        member_selector = unscoped.member(cur_user)
        readable_selector = unscoped.readable(cur_user, site: cur_site).selector
        all.and_public.ne(user_id: cur_user.id).where('$and' => [{ '$or' => [ member_selector, readable_selector ] }])
      end
    end
  end

  def state_options
    %w(public closed).map do |v|
      [ I18n.t("gws/report.options.file_state.#{v}"), v ]
    end
  end

  def public?
    state == 'public'
  end

  def closed?
    !public?
  end

  # override Gws::Addon::Reminder#reminder_url
  def reminder_url(*args)
    ret = super
    options = ret.extract_options!
    options[:state] = 'all'
    [ *ret, options ]
  end

  private

  def send_notification_mail
    added_member_ids = removed_member_ids = []

    if state == 'public'
      cur_member_ids = sorted_overall_members.pluck(:id)
      prev_member_ids = sorted_overall_members_was.pluck(:id)

      if state_was == 'closed'
        # just published
        added_member_ids = cur_member_ids
        removed_member_ids = []
      else
        added_member_ids = cur_member_ids - prev_member_ids
        removed_member_ids = prev_member_ids - cur_member_ids
      end
    end

    if state == 'closed' && state_was == 'public'
      # just depublished
      cur_member_ids = sorted_overall_members.pluck(:id)
      prev_member_ids = sorted_overall_members_was.pluck(:id)

      added_member_ids = []
      removed_member_ids = (cur_member_ids + prev_member_ids).uniq
    end

    return if added_member_ids.blank? && removed_member_ids.blank?

    job = Gws::Report::NotificationJob.bind(site_id: @cur_site || site)
    job.perform_now(id.to_s, added_member_ids, removed_member_ids)
  end
end
