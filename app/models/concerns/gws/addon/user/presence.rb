module Gws::Addon::User::Presence
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :user_presences, class_name: "Gws::UserPresence", dependent: :destroy, inverse_of: :user
  end

  def user_presence(site)
    @_user_presence ||= begin
      item = user_presences.site(site).first
      if item.nil?
        item = Gws::UserPresence.new
        item.cur_site = site
        item.cur_user = self
        item.save
      end
      item
    end
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
    reset_states = SS.config.gws.dig("presence", "sync_available", "presence_logged_in", "reset").to_a
    enter_state = SS.config.gws.dig("presence", "sync_available", "presence_logged_in", "enter")

    user_presences.each do |item|
      next if !item.sync_available_enabled?
      next if item.state.present? && !reset_states.include?(item.state)

      item.state = enter_state
      item.save
    end
  end

  def presence_logged_out
    reset_states = SS.config.gws.dig("presence", "sync_available", "presence_logged_out", "reset").to_a
    leave_state = SS.config.gws.dig("presence", "sync_available", "presence_logged_out", "leave")

    user_presences.each do |item|
      next if !item.sync_unavailable_enabled?
      next if item.state.present? && !reset_states.include?(item.state)

      item.state = leave_state
      item.save
    end
  end

  def presence_punch(site, field_name)
    enter_state = SS.config.gws.dig("presence", "sync_timecard", "presence_punch", "enter")
    leave_state = SS.config.gws.dig("presence", "sync_timecard", "presence_punch", "leave")

    item = user_presence(site)
    return if !item.sync_timecard_enabled?

    case field_name
    when "enter"
      item.state = enter_state
      item.save
    when "leave"
      item.state = leave_state
      item.save
    end
  end
end
