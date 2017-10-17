module Gws::Monitor::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :monitor_new_days, type: Integer
    field :monitor_file_size_per_topic, type: Integer
    field :monitor_file_size_per_post, type: Integer
    field :monitor_browsed_delay, type: Integer
    attr_accessor :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb

    permit_params :monitor_new_days, :monitor_browsed_delay
    permit_params :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb

    before_validation :set_monitor_file_size_per_topic
    before_validation :set_monitor_file_size_per_post
  end

  def monitor_new_days
    self[:monitor_new_days].presence || 7
  end

  def monitor_browsed_delay
    self[:monitor_browsed_delay].presence || 2
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

