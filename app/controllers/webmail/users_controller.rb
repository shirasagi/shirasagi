class Webmail::UsersController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::User

  # prepend_view_path "app/views/ss/roles"

  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_selected_items, only: [:destroy_all, :lock_all, :unlock_all]

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/user"), { action: :index } ]
  end

  def fix_params
    { cur_user: @cur_user }
  end

  def set_items
    @items = @model.all.allow(:read, @cur_user).state(params.dig(:s, :state)).search(params[:s])
  end

  def set_item
    @item = @model.all.allow(:read, @cur_user).find(params[:id])
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user)

    @items = @items.order_by(_id: -1).
      page(params[:page]).per(50)
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user)

    @item = @model.new
    return if request.get?

    @item = Webmail::UserExport.new params.require(:item).permit(Webmail::UserExport.permitted_fields).merge(fix_params)
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :import }, render: { file: :import }
  end

  def download
    raise "403" unless @model.allowed?(:edit, @cur_user)

    items = @model.all.allow(:edit, @cur_user).reorder(id: 1)
    @item = Webmail::UserExport.new
    send_data @item.export_csv(items), filename: "webmail_accounts_#{Time.zone.now.to_i}.csv"
  end

  def download_template
    raise "403" unless @model.allowed?(:edit, @cur_user)

    items = @model.all.allow(:edit, @cur_user).reorder(id: 1)
    @item = Webmail::UserExport.new
    send_data @item.export_template_csv(items), filename: "webmail_accounts_template.csv"
  end
end
