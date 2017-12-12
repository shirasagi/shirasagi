module Gws::Monitor::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :monitor_new_days, type: Integer
    field :monitor_file_size_per_topic, type: Integer
    field :monitor_file_size_per_post, type: Integer
    field :monitor_browsed_delay, type: Integer
    field :monitor_delete_threshold, type: Integer, default: 8
    field :default_reminder_start_section, type: String
    attr_accessor :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb

    permit_params :monitor_new_days, :monitor_browsed_delay
    permit_params :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb
    permit_params :monitor_delete_threshold, :default_reminder_start_section

    before_validation :set_monitor_file_size_per_topic
    before_validation :set_monitor_file_size_per_post
  end

  def monitor_new_days
    self[:monitor_new_days].presence || 7
  end

  def monitor_browsed_delay
    self[:monitor_browsed_delay].presence || 2
  end

  def monitor_delete_threshold_options
    I18n.t('gws/monitor/group_setting.options.monitor_delete_threshold').
        map.
        with_index.
        to_a
  end

  def monitor_delete_threshold_name
    I18n.t('gws/monitor/group_setting.options.monitor_delete_threshold')[monitor_delete_threshold]
  end

  def default_reminder_start_section_options
    options =Gws::Monitor::Topic.new.reminder_start_section_options
    options.insert(0, [nil, nil])
  end

  def default_reminder_start_section_name
    Gws::Monitor::Topic.new.reminder_start_section_options.each do |name, value|
      return name if value == default_reminder_start_section
    end
    nil
  end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Monitor::Category.allowed?(action, user, opts)
      super
    end
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

