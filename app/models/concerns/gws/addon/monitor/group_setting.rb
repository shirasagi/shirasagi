module Gws::Addon::Monitor::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    attr_accessor :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb

    field :monitor_new_days, type: Integer
    field :monitor_file_size_per_topic, type: Integer
    field :monitor_file_size_per_post, type: Integer
    field :monitor_delete_threshold, type: String, default: '24.months'
    field :default_reminder_start_section, type: String

    permit_params :monitor_new_days
    permit_params :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb
    permit_params :monitor_delete_threshold, :default_reminder_start_section

    before_validation :set_monitor_file_size_per_topic
    before_validation :set_monitor_file_size_per_post
  end

  def monitor_new_days
    self[:monitor_new_days].presence || 7
  end

  def monitor_delete_threshold_options
    I18n.t('gws/monitor.options.monitor_delete_threshold').to_a.map { |k, n| [n, k.to_s] }
  end

  def default_reminder_start_section_options
    Gws::Monitor::Topic.new.reminder_start_section_options
  end

  private

  def set_monitor_file_size_per_topic
    return if in_monitor_file_size_per_topic_mb.blank?
    self.monitor_file_size_per_topic = Integer(in_monitor_file_size_per_topic_mb) * 1_024 * 1_024
  end

  def set_monitor_file_size_per_post
    return if in_monitor_file_size_per_post_mb.blank?
    self.monitor_file_size_per_post = Integer(in_monitor_file_size_per_post_mb) * 1_024 * 1_024
  end
end

