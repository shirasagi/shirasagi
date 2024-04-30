class Gws::Ldap::Sync::DryRunsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/sync/main/navi"
  menu_view nil

  model Gws::Ldap::SyncTask

  before_action :check_ldap_url, only: %i[show]
  helper_method :dry_run_results?, :dry_run_groups, :dry_run_users

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
      render
      return
    end
  end

  def dry_run_results?
    path = "#{@item.base_dir}/dry_run.zip"
    ::File.size?(path)
  end

  def dry_run_groups
    @dry_run_groups ||= begin
      path = "#{@item.base_dir}/dry_run.zip"
      groups = []

      Zip::File.open(path) do |zip|
        zip.each do |entry|
          name = entry.name
          name.force_encoding(Encoding::UTF_8)
          next unless name.start_with?("collections/#{Gws::Group.collection_name}/")

          json = entry.get_input_stream.read
          json = JSON.parse(json)
          json["basename"] = ::File.basename(name, ".*")
          groups << ::Mongoid::Factory.from_db(Gws::Group, json)
        end
      end

      groups
    end
  end

  def dry_run_users
    @dry_run_users ||= begin
      path = "#{@item.base_dir}/dry_run.zip"
      users = []

      Zip::File.open(path) do |zip|
        zip.each do |entry|
          name = entry.name
          name.force_encoding(Encoding::UTF_8)
          next unless name.start_with?("collections/#{Gws::User.collection_name}/")

          json = entry.get_input_stream.read
          json = JSON.parse(json)
          json["basename"] = ::File.basename(name, ".*")
          users << ::Mongoid::Factory.from_db(Gws::User, json)
        end
      end

      users
    end
  end

  public

  def show
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    respond_to do |format|
      format.html { render }
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
