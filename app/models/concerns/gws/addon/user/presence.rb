module Gws::Addon::User::Presence
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :user_presences, class_name: "Gws::UserPresence", dependent: :delete_all, inverse_of: :user
  end

  def user_presence(site)
    @_user_presence ||= user_presences.site(site).first
  end

  def presence_title_manageable_users
    editable_users = []
    return editable_users unless title

    title.presence_editable_titles.each do |title|
      editable_users += title.users.to_a
    end
    editable_users.uniq(&:id)
  end

  def presence_logged_in
    user_presences.each do |item|
      next if !item.sync_available_enabled?
      next if %w(available leave dayoff).include?(item.state)

      item.state = "available"
      item.save
    end
  end

  def presence_logged_out
    user_presences.each do |item|
      next if !item.sync_unavailable_enabled?
      next if %w(unavailable leave dayoff).include?(item.state)

      item.state = "unavailable"
      item.save
    end
  end
end
