module Gws::Addon::Board::NotifySetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::NotifySetting

  included do
    field :subscribed_users_readable_state, type: String, default: "admin"
    field :notification_noticed_at, type: DateTime
    permit_params :subscribed_users_readable_state
  end

  def subscribed_users_readable_state_options
    %w(admin subscriber).map do |v|
      [I18n.t("gws/board.options.subscribed_users_readable_state.#{v}"), v]
    end
  end

  def subscribed_users_readable?(user)
    return false unless notify_enabled?

    if subscribed_users_readable_state == "subscriber"
      subscribed_users.in(id: user.id).present?
    else
      ids = user_ids
      #groups.each do |g|
      #  ids += g.users.pluck(:id)
      #end

      role_ids = Gws::Role.site(site).all_in(
        permissions: %w(read_other_gws_board_topics edit_other_gws_board_topics delete_other_gws_board_topics)
      ).pluck(:id)

      conds = []
      conds << { id: { '$in' => ids } }
      conds << { gws_role_ids: { '$in' => role_ids } }
      Gws::User.where('$and' => [ { '$or' => conds } ]).pluck(:id).include?(user.id)
    end
  end
end
