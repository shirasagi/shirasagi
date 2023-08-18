module Gws::Addon::Workload::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Break

  set_addon_type :organization

  included do
    field :workload_default_due_date, type: Integer, default: 7
    field :workload_max_member, type: Integer
    field :workload_filesize_limit, type: Integer
    field :workload_delete_threshold, type: Integer, default: 3
    field :workload_files_break, type: String, default: 'vertically'
    field :workload_new_days, type: Integer

    permit_params :workload_default_due_date, :workload_max_member,
      :workload_filesize_limit, :workload_delete_threshold,
      :workload_files_break, :workload_new_days

    validates :workload_default_due_date, numericality: true
    validates :workload_delete_threshold, numericality: true
    validates :workload_files_break, inclusion: { in: %w(vertically horizontal), allow_blank: true }

    alias_method :workload_files_break_options, :break_options
  end

  def workload_delete_threshold_options
    I18n.t('gws/workload.options.workload_delete_threshold').
      map.
      with_index.
      to_a
  end

  def workload_delete_threshold_name
    I18n.t('gws/workload.options.workload_delete_threshold')[workload_delete_threshold]
  end

  def workload_filesize_limit_in_bytes
    return if workload_filesize_limit.blank?

    workload_filesize_limit * 1_024 * 1_024
  end

  def workload_new_days
    self[:workload_new_days].presence || 7
  end
end
