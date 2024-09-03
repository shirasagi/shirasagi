class Gws::Workflow2::Form::ApplicationsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow2::Form::Application

  navi_view "gws/workflow2/main/navi"

  helper_method :addons, :categories_in_order, :purposes_in_order, :category_filter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow2_label || t('modules.gws/workflow2'), gws_workflow2_setting_path]
    @crumbs << [t("gws/workflow2.navi.form.application"), url_for(action: :index)]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def categories_in_order(item = nil)
    @categories_in_order ||= begin
      criteria = Gws::Workflow2::Form::Category.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, name: 1)
      criteria.to_a
    end

    return @categories_in_order unless item

    @categories_in_order.lazy.select { |cate| item.category_ids.include?(cate.id) }
  end

  def purposes_in_order(item)
    @purposes_in_order ||= begin
      criteria = Gws::Workflow2::Form::Purpose.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, name: 1)
      criteria.to_a
    end

    @purposes_in_order.lazy.select { |cate| item.purpose_ids.include?(cate.id) }
  end

  def addons
    return @addons if instance_variable_defined?(:@addons)

    @addons = @item.addons

    # move Gws::Addon::Workflow2::ColumnSetting to top
    source_index = @addons.find_index { |addon| addon.klass == Gws::Addon::Workflow2::ColumnSetting }
    if !source_index.nil?
      @addons.insert(0, @addons.delete_at(source_index))
    end

    # move Gws::Addon::Workflow2::DestinationSetting after Gws::Addon::Workflow2::FormPurpose
    source_index = @addons.find_index { |addon| addon.klass == Gws::Addon::Workflow2::DestinationSetting }
    target_index = @addons.find_index { |addon| addon.klass == Gws::Addon::Workflow2::FormPurpose }
    if !source_index.nil? && !target_index.nil?
      @addons.insert(target_index + 1, @addons.delete_at(source_index))
    end

    @addons
  end

  def category_filter
    @category_filter ||= begin
      filter = Gws::CategoryFilter.new(
        cur_site: @cur_site, cur_user: @cur_user, category_model: Gws::Workflow2::Form::Category)
      base64_filter = params.dig(:s, :category_filter)
      filter.base64_filter = base64_filter if base64_filter.present? && base64_filter != "-"
      filter
    end
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      if category_filter.present?
        s[:category_criteria] = category_filter.to_mongoid_criteria
      else
        s[:category_criteria] = nil
      end
      s
    end
  end

  public

  def index
    # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    set_search_params

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(@s).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    return render_create(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true)

    result = @item.save

    create_opts = {}
    create_opts[:location] = gws_workflow2_form_form_columns_path(form_id: @item) if result
    render_create result, create_opts
  end

  def publish
    set_item
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    if @item.public?
      redirect_to({ action: :show }, { notice: t('ss.notice.published') })
      return
    end
    return if request.get? || request.head?

    @item.state = 'public'
    render_opts = { render: { template: "publish" }, notice: t('ss.notice.published') }
    render_update @item.save, render_opts
  end

  def depublish
    set_item
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    if @item.closed?
      redirect_to({ action: :show }, { notice: t('ss.notice.depublished') })
      return
    end
    return if request.get? || request.head?

    @item.state = 'closed'
    render_opts = { render: { template: "depublish" }, notice: t('ss.notice.depublished') }
    render_update @item.save, render_opts
  end

  def copy
    set_item
    raise "404" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      @item.name = "#{t("gws/notice.prefix.copy")} #{@item.name}"
      render
      return
    end

    service = Gws::Column::CopyService.new(cur_site: @cur_site, cur_user: @cur_user, model: @model, item: @item)
    service.overwrites = params.require(:item).permit(:name)
    service.overwrites[:state] = "closed"
    result = service.call
    if result
      @item = service.new_item
    else
      SS::Model.copy_errors(service, @item)
    end
    render_create result, render: { template: "copy" }, notice: t("ss.notice.copied")
  end
end
