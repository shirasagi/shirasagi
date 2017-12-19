class Gws::Monitor::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic

  before_action :set_item, only: [
    :show, :edit, :update, :delete, :destroy,
    :public, :preparation, :question_not_applicable, :answered
  ]

  before_action :set_selected_items, only: [
      :destroy_all, :public_all,
      :preparation_all, :question_not_applicable_all
  ]

  before_action :set_category

  private

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [@category.name, action: :index]
    else
      @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), action: :index]
    end
  end

  def set_category
    @categories = Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    current_category_id = super
    if @category.present?
      current_category_id[:category_ids] = [ @category.id ]
    end
    current_category_id
  end

  public

  def index
    @items = @model.site(@cur_site).topic
    @items = @items.and_public

    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    custom_group_ids = []
    Gws::CustomGroup.site(@cur_site).each do |custom_group|
      custom_group_ids.push(custom_group._id) if custom_group.member_ids.include?(@cur_user.id)
    end

    @items = @items.search(params[:s]).
        custom_order(params.dig(:s, :sort) || 'updated_desc').
        and_topics(@cur_user.id, @cur_group.id, custom_group_ids, params.dig(:s, :answerble_article) || 'answerble').
        page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.readable?(@cur_user, @cur_site)
    render file: "/gws/monitor/main/show_#{@item.mode}"
  end

  def create
    @item = @model.new get_params

    @item.attributes["readable_group_ids"] = (@item.attend_group_ids + @item.readable_group_ids).uniq

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save, {location: {controller: 'admins', action: 'show', id: @item._id}}
  end

  def read
    set_item
    raise '403' unless @item.readable?(@cur_user)

    result = true
    if !@item.browsed?(@cur_user)
      @item.set_browsed(@cur_user)
      @item.record_timestamps = false
      result = @item.save
    end

    if result
      respond_to do |format|
        format.html { redirect_to({ action: :show }, { notice: t('ss.notice.saved') }) }
        format.json { render json: { _id: @item.id, browsed_at: @item.browsed_at(@cur_user) }, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render({ file: :edit }) }
        format.json { render(json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type) }
      end
    end
  end

  def public
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "public")
    @item.save
    render_update@item.update
  end

  def preparation
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "preparation")
    @item.save
    render_update@item.update
  end

  def question_not_applicable
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "question_not_applicable")
    @item.save
    render_update@item.update
  end

  def answered
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "answered")
    @item.save
    render_update@item.update
  end

  def public_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "public")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def preparation_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "preparation")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def question_not_applicable_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "question_not_applicable")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def forward
    set_item
    @item.id = 0
    @item.attend_group_ids = []
    @item.readable_group_ids = []
    @item.readable_member_ids  = []
    @item.readable_custom_group_ids = []
    @item.state_of_the_answers_hash = {}
    @item.file_ids = []
    @item.created = nil
    @item.updated = nil
    @item.user_ids = [@cur_user.id]
    @item.group_ids = [@cur_group.id]
    @model = @item.dup
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
    render file: :new
  end
end

