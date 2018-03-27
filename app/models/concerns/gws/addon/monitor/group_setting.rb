module Gws::Addon::Monitor::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Break

  set_addon_type :organization

  included do
    attr_accessor :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb

    field :monitor_new_days, type: Integer
    field :monitor_file_size_per_topic, type: Integer
    field :monitor_file_size_per_post, type: Integer
    field :monitor_delete_threshold, type: String, default: '24.months'
    field :default_notice_state, type: String
    field :monitor_files_break, type: String, default: 'vertically'

    permit_params :monitor_new_days
    permit_params :in_monitor_file_size_per_topic_mb, :in_monitor_file_size_per_post_mb
    permit_params :monitor_delete_threshold, :default_notice_state
    permit_params :monitor_files_break

    before_validation :set_monitor_file_size_per_topic
    before_validation :set_monitor_file_size_per_post

    validates :monitor_files_break, inclusion: { in: %w(vertically horizontal), allow_blank: true }

    alias_method :monitor_files_break_options, :break_options
  end

  def monitor_new_days
    self[:monitor_new_days].presence || 7
  end

  def monitor_delete_threshold_options
    I18n.t('gws/monitor.options.monitor_delete_threshold').to_a.map { |k, n| [n, k.to_s] }
  end

  def default_notice_state_options
    Gws::Monitor::Topic.new.notice_state_options
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

