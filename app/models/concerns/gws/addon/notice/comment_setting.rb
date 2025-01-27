module Gws::Addon::Notice::CommentSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :comment_state, type: String, default: ->{ self.class.default_comment_state }
    permit_params :comment_state
    validates :comment_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def comment_state_options
    %w(disabled enabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def comment_state_enabled?
    comment_state == 'enabled'
  end

  module ClassMethods
    def default_comment_state
      SS.config.gws.notice_comment_setting["comment_state"]
    end
  end
end
