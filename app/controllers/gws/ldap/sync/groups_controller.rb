class Gws::Ldap::Sync::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/sync/main/navi"
  # menu_view nil

  model Gws::Ldap::SyncTask

  helper_method :dry_run_results?, :dry_run_groups

  private

  def set_crumbs
    @crumbs << [t("ldap.links.ldap"), gws_ldap_main_path]
    @crumbs << [t("ldap.buttons.sync"), gws_ldap_sync_main_path]
    @crumbs << [t("ss.buttons.test_run"), gws_ldap_sync_dry_run_path]
  end

  def set_task
    @task ||= Gws::Ldap::SyncTask.where(group_id: @cur_site).reorder(id: 1).first_or_create
  end

  def set_item
  end

  def dry_run_results?
    set_task
    path = "#{@task.base_dir}/dry_run.zip"
    ::File.size?(path)
  end

  def dry_run_groups
    @dry_run_groups ||= begin
      set_task
      path = "#{@task.base_dir}/dry_run.zip"
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

  # def dry_run_users
  #   @dry_run_users ||= begin
  #     set_task
  #     path = "#{@task.base_dir}/dry_run.zip"
  #     users = []
  #
  #     Zip::File.open(path) do |zip|
  #       zip.each do |entry|
  #         name = entry.name
  #         name.force_encoding(Encoding::UTF_8)
  #         next unless name.start_with?("collections/#{Gws::User.collection_name}/")
  #
  #         json = entry.get_input_stream.read
  #         json = JSON.parse(json)
  #         json["basename"] = ::File.basename(name, ".*")
  #         users << ::Mongoid::Factory.from_db(Gws::User, json)
  #       end
  #     end
  #
  #     users
  #   end
  # end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    raise "404" unless dry_run_results?
    render template: "index"
  end

  def show
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    raise "404" unless dry_run_results?

    path = "#{@task.base_dir}/dry_run.zip"
    Zip::File.open(path) do |zip|
      entry_name = "collections/#{Gws::Group.collection_name}/#{params[:id]}.json"
      entry = zip.find_entry(entry_name)
      raise "404" unless entry

      json = entry.get_input_stream.read
      json = JSON.parse(json)
      @after_item = ::Mongoid::Factory.from_db(Gws::Group, json)
    end
    raise "404" unless @after_item

    if @after_item.id
      @before_item = Gws::Group.site(@cur_site).find(@after_item.id) rescue nil
    end
  end
end
