class Gws::Discussion::ForumsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Discussion::Forum

  navi_view 'gws/discussion/main/navi'

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/discussion'), gws_discussion_forums_path]
  end

  def set_item
    super
    @forum = @item.dup
    @forum.id = @item.id
  end

  def pre_params
    super.merge member_ids: [@cur_user.id]
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    state = params.dig(:s, :state).presence || 'public'

    @items = @model.site(@cur_site).forum.without_deleted

    if state == "public"
      @items = @items.and_public.member(@cur_user)
    else
      @items = @items.allow(:read, @cur_user, site: @cur_site)
    end

    @items.search(params[:s]).
      reorder(order: 1, created: 1).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    result = @item.save
    @item.save_main_topic if result
    render_create result
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  # def destroy
  #   raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
  #   render_destroy @item.destroy
  # end
  #
  # def destroy_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:delete, @cur_user, site: @cur_site)
  #       next if item.destroy
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(entries.size != @items.size)
  # end

  def copy
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    set_item
    if request.get?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}"
      return
    end

    @item.attributes = get_params
    if @item.valid?
      item = @item.save_clone
      item.attributes = get_params
      render_create true, location: { action: :index }, render: { file: :copy }
    else
      render_create false, location: { action: :index }, render: { file: :copy }
    end
  end
end
