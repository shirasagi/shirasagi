class Gws::Tabular::TrashFilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::File

  navi_view "gws/tabular/main/navi"

  before_action :set_trash

  helper_method :cur_space, :forms, :find_views, :cur_form, :cur_release, :cur_view, :list_check_box?

  private

  def set_trash
    @trash = true
  end

  def spaces
    @spaces ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.only(:id, :i18n_name, :order, :updated)
    end
  end

  def cur_space
    @cur_space ||= spaces.find(params[:space])
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria.to_a
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
      criteria.to_a
    end
  end

  def find_views(form)
    views.select { |view| view.form_id == form.id }
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

  def cur_view
    return @cur_view if instance_variable_defined?(:@cur_view)

    view_param = params[:view].to_s.presence
    if view_param != '-'
      @cur_view = views.find { |view| view.form_id == cur_form.id && view.id.to_s == view_param }
      raise "404" unless @cur_view
    end
    if @cur_view.blank? || !@cur_view.is_a?(Gws::Tabular::View::List)
      @cur_view = Gws::Tabular::View::DefaultView.new(cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space)
    end

    @cur_view.site = @cur_site
    @cur_view.space = cur_space
    @cur_view.form = cur_form
    @cur_view
  end

  def set_model
    @model = Gws::Tabular::File[cur_release]
  end

  def set_crumbs
    @crumbs << [ cur_space.name, gws_tabular_main_path(space: cur_space) ]
    @crumbs << [ cur_form.name, gws_tabular_files_path(space: cur_space, form: cur_form) ]
    @crumbs << [ t("ss.links.trash"), url_for(action: :index) ]
  end

  def append_view_paths
    cur_view.view_paths.each do |view_path|
      append_view_path view_path
    end
    append_view_path "app/views/gws/tabular/trash_files"
    append_view_path "app/views/gws/tabular/files"

    super
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def base_items
    @base_items ||= begin
      criteria = @model.site(@cur_site)
      criteria = criteria.only_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      order_hash = cur_view.order_hash
      if order_hash.present?
        criteria = criteria.reorder(order_hash)
      end

      criteria
    end
  end

  def list_check_box?
    true
  end

  def policy_class
    Gws::Tabular::TrashFilesPolicy
  end

  public

  def index
    raise "404" if cur_release.blank?

    set_search_params

    @items = base_items.search(@s).page(params[:page]).per(cur_view.try(:limit_count) || SS.max_items_per_page)
    render template: cur_view.index_template_path
  end

  def undo_delete
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("delete")

    set_item
    raise "403" unless policy_class.undo_delete?(@cur_site, @cur_user, @model, @item)

    if request.get? || request.head?
      render
      return
    end

    @item.record_timestamps = false
    @item.deleted = nil

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { template: "undo_delete" }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.save, render_opts
  end

  def destroy
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("delete")
    raise "403" unless policy_class.destroy?(@cur_site, @cur_user, @model, @item)

    render_destroy @item.destroy
  end
end
