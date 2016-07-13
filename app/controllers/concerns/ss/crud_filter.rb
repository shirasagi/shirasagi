module SS::CrudFilter
  extend ActiveSupport::Concern

  included do
    before_action :prepend_current_view_path
    before_action :append_view_paths
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
    before_action :set_destroy_items, only: [:destroy_all]
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
      args.empty? ? super(file: params[:action]) : super
    end

    def json_content_type
      (browser.ie? && browser.version.to_i <= 9) ? "text/plain" : "application/json"
    end

    def set_item
      @item = @model.find params[:id]
      @item.attributes = fix_params
    rescue Mongoid::Errors::DocumentNotFound => e
      return render_destroy(true) if params[:action] == 'destroy'
      raise e
    end

    def set_destroy_items
      ids = params[:ids]
      raise "400" unless ids
      ids = ids.split(",") if ids.kind_of?(String)
      @items = @model.in(id: ids)
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
      @items.destroy_all
      render_destroy_all true
    end

  private
    def render_create(result, opts = {})
      location = opts[:location].presence || crud_redirect_url || { action: :show, id: @item }
      render_opts = opts[:render].presence || { file: :new }
      notice = opts[:notice].presence || t("views.notice.saved")

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
      render_opts = opts[:render].presence || { file: :edit }
      notice = opts[:notice].presence || t("views.notice.saved")

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
      render_opts = opts[:render].presence || { file: :delete }
      notice = opts[:notice].presence || t("views.notice.saved")

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

    def render_destroy_all(result)
      location = crud_redirect_url || { action: :index }
      notice = result ? { notice: t("views.notice.deleted") } : {}
      errors = @items.map { |item| [item.id, item.errors.full_messages] }

      respond_to do |format|
        format.html { redirect_to location, notice }
        format.json { head json: errors }
      end
    end
end
