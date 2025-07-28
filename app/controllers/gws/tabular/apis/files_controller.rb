class Gws::Tabular::Apis::FilesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Tabular::File

  helper_method :cur_space, :forms, :cur_form, :item_title, :item_csv

  private

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      # API の場合、すべて閲覧できても良い
      # criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria.to_a
    end
  end

  def cur_form
    @cur_form ||= begin
      form_param = params[:form].to_s.presence
      form = forms.find { |form| form.id.to_s == form_param }
      raise "404" unless form
      form.site = form.cur_site = @cur_site
      form.space = form.cur_space = cur_space
      form
    end
  end

  def cur_release
    @cur_release ||= begin
      release = cur_form.current_release
      raise "404" unless release
      release
    end
  end

  def views
    @views ||= begin
      criteria = Gws::Tabular::View::Base.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.in(form_id: forms.map(&:id))
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria.only(:id, :site_id, :space_id, :form_id, :i18n_name, :order, :updated)
    end
  end

  def cur_view
    return @cur_view if instance_variable_defined?(:@cur_view)

    view_param = params[:view].to_s.presence
    if view_param != '-'
      @cur_view = views.where(form_id: cur_form.id, id: view_param).first
    end
    @cur_view ||= begin
      view = views.where(form_id: cur_form.id, default_state: "enabled").first
      view ||= Gws::Tabular::View::DefaultView.new(cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space)
      view
    end

    @cur_view.site = @cur_site
    @cur_view.space = cur_space
    @cur_view.form = cur_form
    @cur_view
  end

  def set_model
    @model = Gws::Tabular::File[cur_release]
  end

  def item_title(item)
    @columns ||= Gws::Tabular.released_columns(cur_release, site: @cur_site)
    @columns ||= cur_form.columns.reorder(order: 1, id: 1).to_a

    column = @columns.first
    value = item.read_tabular_value(column)
    renderer = column.value_renderer(value, :title, cur_site: @cur_site, cur_user: @cur_user, item: item)
    result = view_context.render renderer
    result.strip.html_safe
  end

  def item_csv(item)
    @columns ||= Gws::Tabular.released_columns(cur_release, site: @cur_site)
    @columns ||= cur_form.columns.reorder(order: 1, id: 1).to_a

    column = @columns.first
    item.read_csv_value(column, locale: I18n.locale)
  end

  public

  def index
    @multi = params[:single].blank?

    @selected_ids = params.permit(ids: [])[:ids]

    criteria = @model.site(@cur_site)
    criteria = criteria.without_deleted
    # API の場合、すべて閲覧できても良い
    # criteria = criteria.allow(:read, @cur_user, site: @cur_site)
    order_hash = cur_view.order_hash
    if order_hash.present?
      criteria = criteria.reorder(order_hash)
    else
      criteria = criteria.display_order
    end
    criteria = criteria.search(params[:s])
    criteria = criteria.page(params[:page]).per(SS.max_items_per_page)

    @items = criteria
  end
end
