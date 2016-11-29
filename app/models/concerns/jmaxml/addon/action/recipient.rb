module Jmaxml::Addon::Action::Recipient
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :recipient_users, class_name: "Cms::User"
    embeds_ids :recipient_groups, class_name: "Cms::Group"
    permit_params recipient_user_ids: [], recipient_group_ids: []
  end

  def recipient_emails
    addreeses = recipient_groups.flat_map { |g| g.users.pluck(:email) }
    addreeses.concat(recipient_users.pluck(:email))
    addreeses.uniq.select(&:present?)
  end
end
