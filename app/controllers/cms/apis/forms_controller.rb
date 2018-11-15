class Cms::Apis::FormsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Form

  before_action :set_page_data, only: %i[html]

  private

  def set_page_data
    @page ||= begin
      route = params[:route].to_s

      page = Cms::Page.new(route: route)
      page = page.becomes_with_route

      page.attributes = params.require(:item).permit(page.class.permitted_fields).except("id")
      page.cur_site = page.site = @cur_site
      page.cur_user = @cur_user
      page.lock_owner_id = nil if page.respond_to?(:lock_owner_id)
      page.lock_until = nil if page.respond_to?(:lock_until)
      page.basename = page.basename.sub(/\..+?$/, "") + ".html" if page.basename.present?
      page
    end
  end

  public

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(order: 1, name: 1).
      page(params[:page]).per(50)
  end

  def form
    @item = @model.site(@cur_site).find(params[:id])
    @target = Cms::Page.site(@cur_site).find(params[:item_id]).becomes_with_route if params[:item_id].present?
    render layout: false
  end

  def new_column
    @item = Cms::Form.site(@cur_site).find(params[:id])
    @cur_column = @item.columns.find(params[:column_id])
    render layout: false
  end

  def select_temp_file
    @item = SS::File.find(params[:id])
    @item = @item.copy_if_necessary
    render layout: false
  end

  def html
    if !@page.respond_to?(:form) || @page.form.blank?
      head :no_content
      return
    end

    html = @page.form.html
    if html.present?
      template = Liquid::Template.parse(html)

      render_opts = { "values" => @page.column_values.to_liquid }
      html = template.render(render_opts).html_safe
    else
      html = @page.column_values.map(&:to_html).join.html_safe
    end

    render html: html.html_safe, layout: false
  end
end
