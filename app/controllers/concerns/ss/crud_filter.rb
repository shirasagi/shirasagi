module SS::CrudFilter
  extend ActiveSupport::Concern

  included do
    before_action :prepend_current_view_path
    before_action :append_view_paths
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  end

  private
    def prepend_current_view_path
      prepend_view_path "app/views/#{params[:controller]}"
    end

    def append_view_paths
      append_view_path "app/views/ss/crud"
    end

    def render(*args)
      args.size == 0 ? super(file: params[:action]) : super
    end

    def set_item
      @item = @model.find params[:id]
      @item.attributes = fix_params
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

  private
    def render_create(result, opts = {})
      location = opts[:location].presence || { action: :show, id: @item }

      if result
        respond_to do |format|
          format.html { redirect_to location, notice: t("views.notice.saved") }
          format.json { render json: @item.to_json, status: :created }
        end
      else
        respond_to do |format|
          format.html { render file: :new }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end

    def render_update(result, opts = {})
      location = opts[:location].presence || { action: :show }

      if result
        respond_to do |format|
          format.html { redirect_to location, notice: t("views.notice.saved") }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html { render file: :edit }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end

    def render_destroy(result, opts = {})
      location = opts[:location].presence || { action: :index }

      if result
        respond_to do |format|
          format.html { redirect_to location, notice: t("views.notice.deleted") }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html { render file: :delete }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end
end
