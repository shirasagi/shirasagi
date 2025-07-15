class Gws::Tabular::Gws::FormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::Form

  navi_view "gws/tabular/gws/main/conf_navi"

  before_action :respond_404_if_item_is_public, only: [:edit, :update, :soft_delete, :move]

  helper_method :cur_space

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
    @crumbs << [ t('mongoid.models.gws/tabular/form'), gws_tabular_gws_forms_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space }
  end

  def respond_404_if_item_is_public
    raise "404" if @item.public?
  end

  def base_items
    @base_items ||= begin
      criteria = @model.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.without_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.search(params[:s])
      criteria
    end
  end

  public

  def index
    # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    @items = base_items.page(params[:page]).per(SS.max_items_per_page)
  end

  def publish
    set_item
    unless @item.closed?
      redirect_to url_for(action: :show), notice: t('ss.notice.published')
      return
    end
    return if request.get? || request.head?

    # @item.attributes = get_params
    @item.state = 'publishing'
    render_opts = { render: { template: "publish" }, notice: t('ss.notice.published') }

    if @item.invalid?
      render_update false, render_opts
      return
    end

    criteria = @model.where(id: @item.id, revision: @item.revision)
    result = criteria.find_one_and_update(
      { '$set' => { revision: (@item.revision || 0) + 1, state: 'publishing' } },
      return_document: :after)
    unless result
      @item.errors.add :base, :invalid_updated
      render_update false, render_opts
      return
    end

    @item = result
    Gws::Tabular::FormPublishJob.bind(site_id: @cur_site, user_id: @cur_user).perform_now(@item.id.to_s)

    render_update result, render_opts
  end

  def depublish
    set_item
    if @item.closed?
      redirect_to url_for(action: :show), notice: t('ss.notice.depublished')
      return
    end
    return if request.get? || request.head?

    @item.state = 'closed'
    render_opts = { render: { template: "depublish" }, notice: t('ss.notice.depublished') }
    render_update @item.save, render_opts
  end

  def soft_delete
    raise "404" unless @item.closed?
    super
  end
end
