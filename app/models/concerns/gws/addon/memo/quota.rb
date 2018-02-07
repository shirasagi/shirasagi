module Gws::Addon::Memo::Quota
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_skip_validates_sender_quota
    @in_skip_validates_sender_quota = false
    validate :validate_attached_file_size
    validate :validate_quota, if: -> { send_date_was.blank? }
  end

  def validate_attached_file_size
    return if site.memo_filesize_limit.blank?
    return if site.memo_filesize_limit <= 0

    limit = site.memo_filesize_limit * 1024 * 1024
    size = files.compact.map(&:size).sum

    if size > limit
      errors.add(:base, :file_size_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end
  end

  def validate_quota
    return unless @cur_user
    return unless @cur_site
    return unless @cur_site.memo_quota.to_i > 0

    if !@in_skip_validates_sender_quota
      if quota_over?(@cur_user, @cur_site)
        action = draft? ? I18n.t("ss.buttons.save") : I18n.t("ss.buttons.send")
        errors.add :base, :self_quota_over, action: action
        return
      end
    end

    return if draft?

    self.members.each do |member|
      if quota_over?(member, @cur_site)
        errors.add :base, :member_quota_over, member: member.long_name
      end
    end
  end

  public

  def usage_bytes(user, site)
    @usage_bytes ||= {}
    return @usage_bytes[user.id] if @usage_bytes[user.id]
    @usage_bytes[user.id] = self.collection.aggregate([
      {
        '$match' => {
          "site_id" => site.id,
          "$or" => [
            { "$and" => [ { "user_id" => user.id }, { "deleted.sent" => { "$exists" => false } } ] },
            { "$and" => [ { "member_ids" => { "$in" => [ user.id ] } }, { "deleted.#{user.id}" => { "$exists" => false } } ] }
          ]
        }
      },
      {
        '$group' => {
          _id: nil,
          size: { '$sum' => '$size' }
        }
      }
    ]).first.try(:[], :size) || 0
  end

  def quota_bytes(site)
    site.memo_quota.to_i * 1024 * 1024
  end

  def quota_label(user, site)
    h = ApplicationController.helpers
    usage = quota_over?(user, site) ? quota_bytes(site) : usage_bytes(user, site)
    "#{h.number_to_human_size(usage)}/#{h.number_to_human_size(quota_bytes(site))}"
  end

  def quota_over?(user, site)
    return false if quota_bytes(site) <= 0
    usage_bytes(user, site) >= quota_bytes(site)
  end

  def quota_percentage(user, site)
    return 0 if quota_bytes(site) <= 0
    percentage = (usage_bytes(user, site).to_f / quota_bytes(site).to_f) * 100
    percentage > 100 ? 100 : percentage
  end
end
