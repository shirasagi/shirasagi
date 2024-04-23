class Gws::Ldap::Sync::DryRunsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/sync/main/navi"
  menu_view nil

  model Gws::Ldap::SyncTask

  before_action :check_ldap_url, only: %i[show]

  private

  def set_crumbs
    @crumbs << [t("ldap.links.ldap"), gws_ldap_main_path]
    @crumbs << [t("ldap.buttons.sync"), gws_ldap_sync_main_path]
    @crumbs << [t("ss.buttons.test_run"), url_for(action: :show)]
  end

  def set_item
    @item ||= Gws::Ldap::SyncTask.where(group_id: @cur_site).reorder(id: 1).first_or_create
  end

  def ldap_setting
    @ldap_setting ||= begin
      if @cur_site.ldap_use_state_system?
        Sys::Auth::Setting.instance
      else
        @cur_site
      end
    end
  end

  def check_ldap_url
    if ldap_setting.ldap_url.blank?
      @item.errors.add :base, t("ldap.errors.connection_setting_not_found")
      render template: "gws/ldap/sync/runs/show"
      return
    end
  end

  public

  def show
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    respond_to do |format|
      format.html { render template: "gws/ldap/sync/runs/show" }
      format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @item } }
    end
  end

  def update
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    Gws::Ldap::SyncJob.bind(site_id: @cur_site, user_id: @cur_user, task_id: @item).perform_later(dry_run: true)
    redirect_to url_for(action: :show), notice: t("ss.tasks.started")
  end
end
