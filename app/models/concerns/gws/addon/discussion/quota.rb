module Gws::Addon::Discussion::Quota
  extend ActiveSupport::Concern
  extend SS::Addon
  include ActiveSupport::NumberHelper

  included do
    field :size, type: Integer, default: 0

    before_validation :set_size, if: ->{ comment? }
    validate :validate_attached_file_size, if: ->{ comment? }
    validate :validate_quota, if: ->{ comment? }
  end

  def validate_attached_file_size
    return if site.discussion_filesize_limit.blank?
    return if site.discussion_filesize_limit <= 0

    limit = site.discussion_filesize_limit * 1024 * 1024
    size = files.compact.map(&:size).sum

    if size > limit
      errors.add(:base, :file_size_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end
  end

  def validate_quota
    return unless @cur_user
    return unless @cur_site
    return unless @cur_site.discussion_quota.to_i > 0

    if total_quota_model.try(:over?)
      return errors.add :base, :total_quota_over
    end
    if forum_quota_model.try(:over?)
      return errors.add :base, :forum_quota_over
    end
    if topic_quota_model.try(:over?)
      return errors.add :base, :topic_quota_over
    end
  end

  def total_quota_model
    quota_bytes = @cur_site.discussion_quota.to_i * 1024 * 1024
    return nil if quota_bytes <= 0

    usage_bytes = aggregate_total_usage + size
    usage_bytes -= size_was.to_i if persisted?
    SS::Quota.new({ quota_bytes: quota_bytes, usage_bytes: usage_bytes })
  end

  def forum_quota_model
    item = current_forum
    return nil unless item
    quota_bytes = item.forum_quota.to_i * 1024 * 1024
    return nil if quota_bytes <= 0

    usage_bytes = aggregate_forum_usage(item) + size
    usage_bytes -= size_was.to_i if persisted?
    SS::Quota.new({ quota_bytes: quota_bytes, usage_bytes: usage_bytes })
  end

  def topic_quota_model
    item = current_topic
    return nil unless item
    quota_bytes = item.topic_quota.to_i * 1024 * 1024
    return nil if quota_bytes <= 0

    usage_bytes = aggregate_topic_usage(item) + size
    usage_bytes -= size_was.to_i if persisted?
    SS::Quota.new({ quota_bytes: quota_bytes, usage_bytes: usage_bytes })
  end

  private

  def set_size
    self.size = 1024
    self.size += files.pluck(:size).sum if files.present?
  end

  def aggregate_total_usage
    self.collection.aggregate([
      { '$match' => { "site_id" => site_id } },
      { '$group' => { _id: nil, size: { '$sum' => '$size' } } }
    ]).first.try(:[], :size) || 0
  end

  def aggregate_forum_usage(item)
    self.collection.aggregate([
      {
        '$match' => {
          "site_id" => site_id,
          "$or" => [{ _id: item._id }, { forum_id: item._id }]
        }
      },
      { '$group' => { _id: nil, size: { '$sum' => '$size' } } }
    ]).first.try(:[], :size) || 0
  end

  def aggregate_topic_usage(item)
    self.collection.aggregate([
      {
        '$match' => {
          "site_id" => site_id,
          "$or" => [{ _id: item._id }, { parent_id: item._id }]
        }
      },
      { '$group' => { _id: nil, size: { '$sum' => '$size' } } }
    ]).first.try(:[], :size) || 0
  end
end
