module Gws::Addon::User::Presence
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :user_presences, class_name: "Gws::Presence::UserPresence", dependent: :delete_all, inverse_of: :user
  end

  def user_presence(site)
    @_user_presence ||= user_presences.site(site).first
  end

  def presence_editable_users
    @_editable_users ||= begin
      editable_users = [self]
      return editable_users unless title

      title.presence_editable_titles.each do |title|
        editable_users += title.users.to_a
      end
      editable_users.uniq(&:id)
    end
  end
end
