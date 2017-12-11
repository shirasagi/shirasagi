module Gws::Addon::Circular::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :circular_default_due_date, type: Integer, default: 7
    field :circular_max_member, type: Integer
    field :circular_filesize_limit, type: Integer
    field :circular_delete_threshold, type: Integer, default: 3

    permit_params :circular_default_due_date, :circular_max_member,
                  :circular_filesize_limit, :circular_delete_threshold

    validates :circular_default_due_date, numericality: true
    validates :circular_delete_threshold, numericality: true
  end

  def circular_default_due_date
    self[:circular_default_due_date]
  end

  def circular_max_member
    self[:circular_max_member]
  end

  def circular_filesize_limit
    self[:circular_filesize_limit]
  end

  def circular_delete_threshold
    self[:circular_delete_threshold]
  end

  def circular_delete_threshold_options
    I18n.t('gws/circular/group_setting.options.circular_delete_threshold').
      map.
      with_index.
      to_a
  end

  def circular_delete_threshold_name
    I18n.t('gws/circular/group_setting.options.circular_delete_threshold')[circular_delete_threshold]
  end

  class << self
    def allowed?(action, user, opts = {})
      Gws::Circular::Post.allowed?(action, user, opts)
    end
  end

end

