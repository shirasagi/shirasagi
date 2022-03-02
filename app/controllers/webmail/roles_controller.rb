class Webmail::RolesController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Role

  prepend_view_path "app/views/ss/roles"

  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/role"), { action: :index } ]
  end

  def fix_params
    { cur_user: @cur_user }
  end

  def set_items
    @items = @model.all.allow(:read, @cur_user)
  end

  def set_item
    @item = @items.find(params[:id])
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user)

    @items = @items.order_by(name: 1, id: 1).
      page(params[:page]).per(50)
  end

  def download
    csv = @model.unscoped.order_by(name: 1, id: 1).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "webmail_roles_#{Time.zone.now.to_i}.csv"
  end

  def import
    @item = @model.new
    return if request.get? || request.head?

    file = params.require(:item).permit(:in_file)[:in_file]
    if file.blank?
      @item.errors.add :base, :invalid_csv
      return
    end

    mime = SS::MimeType.find(file.original_filename, file.content_type)
    if mime != "text/csv" || !Webmail::RoleImportJob.valid_csv?(file)
      @item.errors.add :base, :invalid_csv
      return
    end

    temp_file = SS::TempFile.new
    temp_file.in_file = file
    temp_file.save!

    Webmail::RoleImportJob.bind(user_id: @cur_user).perform_now(temp_file.id)
    redirect_to({ action: :index }, { notice: t("ss.notice.saved") })
  end
end
