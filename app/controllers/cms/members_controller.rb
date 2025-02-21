class Cms::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Member

  navi_view "cms/cms/navi"
  menu_view "cms/crud/menu"

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :verify]

  private

  def set_crumbs
    @crumbs << [t("cms.member"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(name: 1, id: 1).
      page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    csv = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(id: 1).
      to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "members_#{Time.zone.now.to_i}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site)

    if request.get?
      @item = @model.new
      render :import
    elsif request.post?
      if params[:item].nil?
        flash.now[:notice] = I18n.t("ss.errors.import.blank_file")
        render :import
        return
      end

      file = params[:item][:in_file]
      Rails.logger.debug{ "POST request for import action with file: #{file.inspect}" }
      if File.extname(file.original_filename).downcase != ".csv"
        flash.now[:notice] = I18n.t("ss.errors.import.invalid_file_type")
        render :import
        return
      end
      result = Cms::Member.import_csv(file, cur_site: @cur_site, cur_user: @cur_user)
      Rails.logger.debug{ "POST request for import action with file: #{result.inspect}" }
      if result[:success]
        flash[:notice] = t("ss.notice.saved")
        Rails.logger.debug{ "Import successful: #{file.inspect}" }
        redirect_to action: :index
      else
        flash.now[:notice] = "#{t("ss.notice.not_saved_successfully")} #{result[:error]}"
        Rails.logger.error{ "Import failed: #{result[:error]}" }
        render :import
      end
    end
  end

  def verify
    raise '404' unless @node = Member::Node::Registration.site(@cur_site).and_public.first
    return if request.get? || request.head?

    Member::Mailer.verification_mail(@item).deliver_now
    @item.verify_mail_sent = Time.zone.now.to_i
    render_update @item.update, notice: I18n.t('ss.notice.sent')
  end
end
