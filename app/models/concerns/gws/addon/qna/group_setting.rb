module Gws::Addon::Qna::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    attr_accessor :in_qna_file_size_per_topic_mb, :in_qna_file_size_per_post_mb

    field :qna_new_days, type: Integer
    field :qna_file_size_per_topic, type: Integer
    field :qna_file_size_per_post, type: Integer
    field :qna_browsed_delay, type: Integer

    permit_params :qna_new_days, :qna_browsed_delay
    permit_params :in_qna_file_size_per_topic_mb, :in_qna_file_size_per_post_mb

    before_validation :set_qna_file_size_per_topic
    before_validation :set_qna_file_size_per_post
  end

  def qna_new_days
    self[:qna_new_days].presence || 7
  end

  def qna_browsed_delay
    self[:qna_browsed_delay].presence || 2
  end

  private

  def set_qna_file_size_per_topic
    return if in_qna_file_size_per_topic_mb.blank?
    self.qna_file_size_per_topic = Integer(in_qna_file_size_per_topic_mb) * 1_024 * 1_024
  end

  def set_qna_file_size_per_post
    return if in_qna_file_size_per_post_mb.blank?
    self.qna_file_size_per_post = Integer(in_qna_file_size_per_post_mb) * 1_024 * 1_024
  end
end
