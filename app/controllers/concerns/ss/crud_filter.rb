module SS::CrudFilter
  extend ActiveSupport::Concern
  include SS::ImplicitRenderFilter

  included do
    before_action :prepend_current_view_path
    before_action :append_view_paths
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
    before_action :set_selected_items, only: [:destroy_all, :change_state_all, :publish_all, :close_all]
    menu_view "ss/crud/menu"
  end

  private

  def prepend_current_view_path
    prepend_view_path "app/views/#{params[:controller]}"
  end

  def append_view_paths
    append_view_path "app/views/ss/crud"
  end

  def render(*args)
    args.empty? ? super(template: params[:action]) : super
  end

  def set_item
    @item ||= begin
      item = @model.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @selected_items = @items = @model.in(id: ids) # filter by site on cms,gws,,
    raise "400" unless @items.present?
  end

  def fix_params
    {}
  end

  def pre_params
    {}
  end

  def permit_fields
    @model.permitted_fields
  end

  def get_params
    params.require(:item).permit(permit_fields).merge(fix_params)
  rescue
    raise "400"
  end

  def crud_redirect_url
    nil
  end

  public

  def index
    @items = @model.all.
      order_by(_id: -1).
      page(params[:page]).per(100)
  end

  def show
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end

  def delete
    render
  end

  def destroy
    render_destroy @item.destroy
  end

  def destroy_all
    raise "400" if @selected_items.blank?

    @selected_items.destroy_all
    render_destroy_all true
  end

  private

  def render_create(result, opts = {})
    location = opts[:location].presence || crud_redirect_url || { action: :show, id: @item }
    render_opts = opts[:render].presence || { template: "new" }
    notice = opts[:notice].presence || t("ss.notice.saved")

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render render_opts }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def render_update(result, opts = {})
    location = opts[:location].presence || crud_redirect_url || { action: :show }
    render_opts = opts[:render].presence || { template: "edit" }
    notice = opts[:notice].presence || t("ss.notice.saved")

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render render_opts }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def render_destroy(result, opts = {})
    location = opts[:location].presence || crud_redirect_url || { action: :index }
    render_opts = opts[:render].presence || { template: "delete" }
    notice = opts[:notice].presence || t("ss.notice.deleted")

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render render_opts }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def render_confirmed_all(result, opts = {})
    action = if %w(close_all change_state_all).include?(params[:action])
               'change'
             else
               'delete'
             end

    location = opts[:location].presence || crud_redirect_url || { action: :index }
    if result
      notice = { notice: opts[:notice].presence || t("ss.notice.#{action}d") }
    else
      notice = { notice: t("ss.notice.unable_to_#{action}", items: @items.to_a.map(&:name).join("、")) }
    end
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html do
        redirect_to location, notice
      end
      format.json do
        head json: errors
      end
    end
  end

  # for backwards compatibility
  alias render_destroy_all render_confirmed_all
end
