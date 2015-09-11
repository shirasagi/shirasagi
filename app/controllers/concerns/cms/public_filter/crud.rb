module Cms::PublicFilter::Crud
  extend ActiveSupport::Concern
  include SS::AgentFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  end

  private
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
      render_opts = opts[:render].presence || { file: :new }
      notice = opts[:notice].presence || t("views.notice.saved")

      if result
        respond_to do |format|
          format.html { redirect_to location, notice: notice }
          format.json { render json: @item.to_json, status: :created }
        end
      else
        respond_to do |format|
          format.html { render render_opts }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end

    def render_update(result, opts = {})
      location = opts[:location].presence || { action: :show }
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
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end

    def render_destroy(result, opts = {})
      location = opts[:location].presence || { action: :index }
      render_opts = opts[:render].presence || { file: :delete }
      notice = opts[:notice].presence || t("views.notice.deleted")

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
end
