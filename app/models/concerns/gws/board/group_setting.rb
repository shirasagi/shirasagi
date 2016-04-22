module Gws::Board::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :board_new_days, type: Integer
    field :board_file_size_per_topic, type: Integer
    field :board_file_size_per_post, type: Integer
    attr_accessor :in_board_file_size_per_topic_mb, :in_board_file_size_per_post_mb

    permit_params :board_new_days
    permit_params :in_board_file_size_per_topic_mb, :in_board_file_size_per_post_mb

    before_validation :set_board_file_size_per_topic
    before_validation :set_board_file_size_per_post
  end

  def board_new_days
    self[:board_new_days].presence || 7
  end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Board::Category.allowed?(action, user, opts)
      super
    end
  end

  private
    def set_board_file_size_per_topic
      return if in_board_file_size_per_topic_mb.blank?
      self.board_file_size_per_topic = Integer(in_board_file_size_per_topic_mb) * 1_024 * 1_024
    end

    def set_board_file_size_per_post
      return if in_board_file_size_per_post_mb.blank?
      self.board_file_size_per_post = Integer(in_board_file_size_per_post_mb) * 1_024 * 1_024
    end
end
