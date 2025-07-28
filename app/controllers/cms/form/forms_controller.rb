class Cms::Form::FormsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Form

  navi_view "cms/form/main/navi"

  helper_method :form_is_in_use?

  private

  def set_crumbs
    @crumbs << [Cms::Form.model_name.human, action: :index]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def form_is_in_use?
    return @form_is_in_use if !@form_is_in_use.nil?

    set_item
    @form_is_in_use = Cms::Page.site(@cur_site).where(form_id: @item.id).present?
  end

  def set_items
    @items = super.order_by(order: 1, name: 1)
  end

  def destroy_items
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      item.cur_user = @cur_user if item.respond_to?(:cur_user)

      if !item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        item.errors.add :base, :auth_error
        @items << item
        next
      end

      if Cms::Page.site(@cur_site).where(form_id: item.id).present?
        item.errors.add :base, :unable_to_delete_all_columns_if_form_is_in_use
        @items << item
        next
      end

      next if item.destroy
      @items << item
    end

    entries.size != @items.size
  end

  public

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    if @item.state == "closed" && form_is_in_use?
      @item.errors.add :base, :unable_to_close_form_if_form_is_in_use
      render_update false
      return
    end

    render_update @item.update
  end

  def delete
    raise "404" if form_is_in_use?
    super
  end

  def destroy
    raise "404" if form_is_in_use?
    super
  end

  def column_form
    set_item
  end

  def column_names
    safe_params = params.permit(ids: [])
    ids = safe_params[:ids]
    ids.select!(&:numeric?)
    ids.map!(&:to_i)

    column_names = Cms::Column::Base.site(@cur_site).in(form_id: ids).pluck(:name)
    column_names.uniq!
    column_names.sort!

    render json: { column_names: column_names }
  end

  def download
    set_items

    @items = @items.where(:id.in => params[:ids]) if params[:ids].present?
    @items = @items.allow(:read, @cur_user, site: @cur_site, node: @cur_node)

    json = JSON.pretty_generate(@model.export_json(@items))
    send_data json, type: :json, filename: "cms_forms_#{Time.zone.now.to_i}.json"
  end

  def import
    @item = @model.new fix_params
    return unless request.post?

    in_params = params.require(:item).permit(:in_file)
    return unless @item.import_json(file: in_params[:in_file])

    redirect_to({ action: :index }, { notice: I18n.t("ss.notice.imported") })
  end
end
