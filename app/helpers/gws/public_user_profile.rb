module Gws::PublicUserProfile
  extend ActiveSupport::Concern

  def gws_public_user_profile(user, *attributes, **options)
    html = []
    cur_site = options[:cur_site] || @cur_site

    attributes.each do |attribute|
      case attribute
      when :uid_or_id
        if cur_site.user_profile_public?("uid")
          html << "<span class=\"id\">##{user.uid.presence || user.id}</span>"
        else
          html << "<span class=\"id\">##{user.id}</span>"
        end
      when :updated
        if cur_site.user_profile_public?("updated")
          html << "<span class=\"datetime\">#{user.updated.try { |time| I18n.l(time, format: :picker) }}</span>"
        end
      when :main_group
        if cur_site.user_profile_public?("main_group")
          html << "<span class=\"group\">#{user.gws_main_group(cur_site).try { |group| group.trailing_name }}</span>"
        end
      when :main_group_section_name
        if cur_site.user_profile_public?("main_group")
          html << "<span class=\"group\">#{user.gws_main_group(cur_site).try { |group| group.section_name }}</span>"
        end
      when :user_title
        if cur_site.user_profile_public?("user_title")
          title = user.title(cur_site)
          if title
            html << "<span class=\"user-title\">#{title.name}</span>"
          end
        end
      when :email
        if cur_site.user_profile_public?("email") && user.email.present?
          html << "<span class=\"email js-clipboard-copy\">#{user.email}</span>"
        end
      when :tel
        if cur_site.user_profile_public?("tel") && user.tel_label.present?
          html << "<span class=\"tel\">#{user.tel_label}</span>"
        end
      end
    end

    html.join("\n").html_safe
  end
end
