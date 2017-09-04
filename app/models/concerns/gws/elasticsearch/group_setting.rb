module Gws::Elasticsearch::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :elasticsearch_state, type: String, default: 'disabled'
    field :elasticsearch_hosts, type: SS::Extensions::Words

    permit_params :elasticsearch_state, :elasticsearch_hosts

    validates :elasticsearch_state, presence: true, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  # def board_new_days
  #   self[:board_new_days].presence || 7
  # end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Board::Category.allowed?(action, user, opts)
      super
    end
  end

  def elasticsearch_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  private

  # def set_board_file_size_per_topic
  #   return if in_board_file_size_per_topic_mb.blank?
  #   self.board_file_size_per_topic = Integer(in_board_file_size_per_topic_mb) * 1_024 * 1_024
  # end
  #
  # def set_board_file_size_per_post
  #   return if in_board_file_size_per_post_mb.blank?
  #   self.board_file_size_per_post = Integer(in_board_file_size_per_post_mb) * 1_024 * 1_024
  # end
end
