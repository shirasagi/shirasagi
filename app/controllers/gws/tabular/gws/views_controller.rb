class Gws::Tabular::Gws::ViewsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::View::Base

  navi_view "gws/tabular/gws/main/conf_navi"

  helper_method :cur_space, :view_type_options, :forms_options

  private

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def set_crumbs
    @crumbs << [ t('modules.gws/tabular'), gws_tabular_gws_main_path ]
    @crumbs << [ t('mongoid.models.gws/tabular/space'), gws_tabular_gws_spaces_path ]
    @crumbs << [ cur_space.name, gws_tabular_gws_space_path(id: cur_space) ]
    @crumbs << [ t('mongoid.models.gws/tabular/view/base'), gws_tabular_gws_forms_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space }
  end

  def view_type_options
    @view_type_options ||= begin
      items = {}

      Gws::Tabular::View.plugins.each do |plugin|
        mod = plugin.module_key
        items[mod] = { name: plugin.i18n_module_name, items: [] } if !items[mod]
        items[mod][:items] << [ plugin.i18n_name_only, plugin.path ]
      end

      items
    end
  end

  def set_view_model
    type = params[:type].to_s.presence
    raise "404" if type.blank?

    plugin = Gws::Tabular::View.find_plugin_by_path(type.to_s)
    raise "404" unless plugin

    model = plugin.model_class
    raise "404" unless model

    @model = model
  end

  def forms_options
    @forms_options ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, name: 1)

      forms = criteria.only(:id, :_id, :i18n_name).to_a
      forms.map { |form| [ form.name, form.id.to_s ] }
    end
  end

  def base_items
    @base_items ||= begin
      criteria = @model.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.search(params[:s])
      criteria
    end
  end

  def set_item
    super
    @model = @item.class
  end

  public

  class NewPrerequisiteParams
    extend SS::Translation
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :cur_user, :cur_site, :cur_space

    attribute :type, :string
    attribute :form_id, :string

    validate :validate_type
    validate :validate_form_id

    def view_model
      plugin = Gws::Tabular::View.find_plugin_by_path(type)
      return if plugin.blank? || plugin.disabled?

      plugin.model_class
    end

    private

    def validate_type
      self.type = type.to_s.strip
      if type.blank?
        errors.add :type, :blank
        return
      end

      plugin = Gws::Tabular::View.find_plugin_by_path(type)
      if plugin.blank? || plugin.disabled?
        errors.add :type, :inclusion
        return
      end

      model = plugin.model_class
      if model.nil?
        errors.add :type, :inclusion
      end
    end

    def validate_form_id
      self.form_id = form_id.to_s.strip
      if form_id.blank?
        errors.add :form_id, :blank
        return
      end

      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.where(id: form_id.to_s)
      if criteria.blank?
        errors.add :form_id, :inclusion
      end
    end
  end

  def index
    # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    @items = base_items.page(params[:page]).per(SS.max_items_per_page)
  end

  def new
    raise "403" unless Gws::Tabular::View::Base.allowed?(:edit, @cur_user, site: @cur_site)
    if params[:next].blank?
      @model = NewPrerequisiteParams
      @item = @model.new pre_params.merge(fix_params)

      render "new_prerequisite"
      return
    end

    new_params = NewPrerequisiteParams.new pre_params.merge(fix_params)
    new_params.attributes = params.require(:item).permit(:type, :form_id)
    if new_params.invalid?
      @model = new_params.class
      @item = new_params
      render "new_prerequisite"
      return
    end

    @model = new_params.view_model
    @item = @model.new pre_params.merge(fix_params)
    @item.form_id = new_params.form_id
    render template: "new"
  end

  def create
    raise "403" unless Gws::Tabular::View::Base.allowed?(:edit, @cur_user, site: @cur_site)

    set_view_model
    @item = @model.new get_params
    return render_create(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true)
    render_create @item.save
  end
end
