module Gws::Addon::Board::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Break

  set_addon_type :organization

  included do
    attr_accessor :in_board_file_size_per_topic_mb, :in_board_file_size_per_post_mb

    field :board_new_days, type: Integer
    field :board_file_size_per_topic, type: Integer
    field :board_file_size_per_post, type: Integer
    field :board_browsed_delay, type: Integer
    field :board_files_break, type: String, default: 'vertically'
    field :board_links_break, type: String, default: 'vertically'

    permit_params :board_new_days, :board_browsed_delay
    permit_params :in_board_file_size_per_topic_mb, :in_board_file_size_per_post_mb
    permit_params :board_files_break, :board_links_break

    before_validation :set_board_file_size_per_topic
    before_validation :set_board_file_size_per_post

    validates :board_files_break, :board_links_break, inclusion: { in: %w(vertically horizontal), allow_blank: true }

    alias_method :board_files_break_options, :break_options
    alias_method :board_links_break_options, :break_options
  end

  def board_new_days
    self[:board_new_days].presence || 7
  end

  def board_browsed_delay
    self[:board_browsed_delay].presence || 2
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
