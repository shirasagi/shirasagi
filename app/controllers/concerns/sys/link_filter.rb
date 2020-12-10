module Sys::LinkFilter
  extend ActiveSupport::Concern

  included do
    helper_method :avaiable_sys_links
    helper_method :sys_conf_path
  end

  private

  def avaiable_sys_links
    @links ||= begin
      links = []

      if Sys::Group.allowed?(:edit, @cur_user)
        links << [ t("sys.group"), sys_groups_path ]
      end
      if SS::User.allowed?(:edit, @cur_user)
        links << [ t("sys.user"), sys_users_path ]
      end
      if Sys::Role.allowed?(:edit, @cur_user)
        links << [ t("sys.role"), sys_roles_path ]
      end
      if SS::User.allowed?(:edit, @cur_user)
        links << [ t("sys.auth"), sys_auth_path ]
      end

      if Sys::Site.allowed?(:edit, @cur_user)
        links << [ t("sys.site"), sys_sites_path ]
      end
      if Sys::Site.allowed?(:edit, @cur_user)
        links << [ t("sys.site_copy"), sys_site_copy_path ]
      end

      if Sys::Notice.allowed?(:edit, @cur_user)
        links << [ t("sys.notice"), sys_notice_index_path ]
      end
      if Sys::Setting.allowed?(:edit, @cur_user)
        links << [ t("sys.menu_settings"), sys_menu_settings_path ]
        links << [ t("sys.password_policy"), sys_password_policy_path ]
        links << [ t("sys.postal_code"), sys_postal_codes_path ]
        links << [ t("sys.prefecture_code"), sys_prefecture_codes_path ]
        links << [ t("sys.max_file_size"), sys_max_file_sizes_path ]
        links << [ t("sys.ad"), sys_ad_path ]
      end

      if SS::User.allowed?(:edit, @cur_user)
        links << [ t("sys.diag"), sys_diag_main_path ]
        links << [ t("job.main"), job_sys_main_path ]
        links << [ t("history.log"), history_sys_logs_path ]
      end

      if Sys::MailLog.allowed?(:edit, @cur_user)
        links << [ Sys::MailLog.model_name.human, sys_mail_logs_path ]
      end

      links
    end
  end

  def sys_conf_path
    links = avaiable_sys_links
    return if links.blank?

    return links.first[1]
  end
end
