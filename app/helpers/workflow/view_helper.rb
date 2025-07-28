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

  def workflow_user_profile_at_application(workflow_user_custom_data)
    name = Gws::Workflow2.find_custom_data_value(workflow_user_custom_data, "name")
    if @cur_site.user_profile_public?("uid")
      uid = Gws::Workflow2.find_custom_data_value(workflow_user_custom_data, "uid")
    end
    if @cur_site.user_profile_public?("email")
      email = Gws::Workflow2.find_custom_data_value(workflow_user_custom_data, "email")
    end

    long_name = name
    long_name = "#{long_name} (#{uid})" if uid.present?

    template = email.present? ? "agent_value_with_email" : "agent_value"
    I18n.t(template, scope: :workflow, long_name: long_name, email: email)
  end
end
