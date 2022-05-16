module Workflow::ViewHelper
  extend ActiveSupport::Concern

  def workflow_user_profile(user)
    return "#{user.long_name}(#{user.email})" if @ss_mode != :gws

    ret = ""
    if @cur_site.user_profile_public?("uid")
      ret += user.long_name
    else
      ret += user.name
    end
    if @cur_site.user_profile_public?("email") && user.email.present?
      ret += "(#{user.email})"
    end

    ret
  end

  def workflow_user_long_name(user)
    return user.long_name if @ss_mode != :gws

    if @cur_site.user_profile_public?("uid")
      user.long_name
    else
      user.name
    end
  end

  def workflow_user_email(user)
    return user.email if @ss_mode != :gws
    return user.email if @cur_site.user_profile_public?("email")
    nil
  end
end
