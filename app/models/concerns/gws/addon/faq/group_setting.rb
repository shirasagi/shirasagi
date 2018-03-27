module Gws::Addon::Faq::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Break

  set_addon_type :organization

  included do
    attr_accessor :in_faq_file_size_per_topic_mb, :in_faq_file_size_per_post_mb

    field :faq_new_days, type: Integer
    field :faq_file_size_per_topic, type: Integer
    field :faq_file_size_per_post, type: Integer
    field :faq_browsed_delay, type: Integer
    field :faq_files_break, type: String, default: 'vertically'

    permit_params :faq_new_days, :faq_browsed_delay
    permit_params :in_faq_file_size_per_topic_mb, :in_faq_file_size_per_post_mb
    permit_params :faq_files_break

    before_validation :set_faq_file_size_per_topic
    before_validation :set_faq_file_size_per_post

    validates :faq_files_break, inclusion: { in: %w(vertically horizontal), allow_blank: true }

    alias_method :faq_files_break_options, :break_options
  end

  def faq_new_days
    self[:faq_new_days].presence || 7
  end

  def faq_browsed_delay
    self[:faq_browsed_delay].presence || 2
  end

  private

  def set_faq_file_size_per_topic
    return if in_faq_file_size_per_topic_mb.blank?
    self.faq_file_size_per_topic = Integer(in_faq_file_size_per_topic_mb) * 1_024 * 1_024
  end

  def set_faq_file_size_per_post
    return if in_faq_file_size_per_post_mb.blank?
    self.faq_file_size_per_post = Integer(in_faq_file_size_per_post_mb) * 1_024 * 1_024
  end
end
