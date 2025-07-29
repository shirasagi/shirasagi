module Gws::Presence::Users::AuthFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_groups
    before_action :set_editable_users
    before_action :set_manageable_users
  end

  def editable_user?(user)
    return true if Gws::UserPresence.allowed?(:manage_all, @cur_user, site: @cur_site)
    return true if @editable_user_ids.include?(user.id)
    return true if @group_user_ids.include?(user.id) && Gws::UserPresence.allowed?(:manage_private, @cur_user, site: @cur_site)
    return true if @custom_group_user_ids.include?(user.id) && Gws::UserPresence.allowed?(:manage_custom_group, @cur_user, site: @cur_site)
    false
  end

  private

  def set_groups
    @groups = [ @cur_site.root ] + @cur_site.root.descendants.active.to_a
  end

  def set_editable_users
    @editable_user_ids = [@cur_user.id] + @cur_user.presence_title_manageable_users.map(&:id)
  end

  def set_manageable_users
    @manage_all = Gws::UserPresence.allowed?(:manage_all, @cur_user, site: @cur_site)

    if Gws::UserPresence.allowed?(:manage_custom_group, @cur_user, site: @cur_site)
      custom_groups = Gws::CustomGroup.site(@cur_site).member(@cur_user).to_a
      @custom_group_user_ids = custom_groups.map { |item| item.members.pluck(:id) }.flatten.uniq
    else
      @custom_group_user_ids = []
    end

    if Gws::UserPresence.allowed?(:manage_private, @cur_user, site: @cur_site)
      @group_user_ids = @cur_user.gws_default_group.users.pluck(:id)
    else
      @group_user_ids = []
    end

    @manageable_user_ids = (@editable_user_ids + @group_user_ids + @custom_group_user_ids).uniq
  end
end
