class Cms::RolesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Role

  prepend_view_path "app/views/ss/roles"
  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.role"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      order_by(name: 1).
      page(params[:page]).per(50)
  end

  def download
    csv = @model.to_csv(@cur_site).encode("SJIS", invalid: :replace, undef: :replace)
    filename = @model.to_s.tableize.gsub(/\//, "_")
    send_data csv, filename: "#{filename}_#{Time.zone.now.to_i}.csv"
  end

  def import
    @item = @model.new
    return if request.get?

    begin
      file = params[:item].try(:[], :file)
      raise I18n.t("errors.messages.invalid_csv") if file.nil? || ::File.extname(file.original_filename) != ".csv"
      CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "cms/role"
      ss_file.save

      # call job
      Cms::Role::ImportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(ss_file.id)
      flash.now[:notice] = I18n.t("ss.notice.started_import")
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @item.errors.add :base, e.to_s
    end
  end
end
