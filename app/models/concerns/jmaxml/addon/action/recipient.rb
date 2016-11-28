module Jmaxml::Addon::Action::Recipient
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :users, class_name: "Cms::User"
    embeds_ids :groups, class_name: "Cms::Group"
    permit_params user_ids: [], group_ids: []
  end

  def recipient_emails
    addreeses = groups.map { |g| g.users.pluck(:email) }
    addreeses << users.pluck(:email)
    addreeses.flatten.uniq.select(&:present?)
  end
end
