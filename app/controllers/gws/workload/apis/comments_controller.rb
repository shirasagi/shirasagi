class Gws::Workload::Apis::CommentsController < ApplicationController
  include Gws::ApiFilter
  include Gws::Memo::NotificationFilter

  model Gws::Workload::WorkComment

  before_action :set_cur_work
  before_action :set_item, only: [:edit, :update, :delete, :destroy]

  private

  def set_cur_work
    @cur_work = Gws::Workload::Work.find(params[:work_id])
    @cur_work.cur_user = @cur_user
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, cur_work: @cur_work }
  end

  def set_item
    @item ||= begin
      item = @cur_work.comments.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def create
    @item = @model.new get_params
    @item.text_type ||= 'plain'
    if !@cur_work.member_user?(@cur_user) && !@cur_work.allowed?(:edit, @cur_user, site: @cur_site)
      raise "403"
    end
    @cur_work.errors.clear

    result = @item.save
    if result
      # set_comments_total
      @cur_work.update

      respond_to do |format|
        format.html { redirect_to URI.parse(params[:redirect_to].to_s).path, notice: t('ss.notice.saved') }
        format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { redirect_to URI.parse(params[:redirect_to].to_s).path, notice: @item.errors.full_messages.join("\n") }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def edit
    raise '403' if @item.user_id != @cur_user.id && !@cur_work.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_work.errors.clear
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' if @item.user_id != @cur_user.id && !@cur_work.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_work.errors.clear

    result = @item.save
    if result
      # set_comments_total
      @cur_work.update
    end

    render_update(result, location: params[:redirect_to])
  end

  def delete
    raise '403' if @item.user_id != @cur_user.id && !@cur_work.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_work.errors.clear

    render
  end

  def destroy
    raise '403' if @item.user_id != @cur_user.id && !@cur_work.allowed?(:edit, @cur_user, site: @cur_site)
    @cur_work.errors.clear

    result = @item.destroy
    if result
      # set_comments_total
      @cur_work.update
    end
    render_destroy(result, location: params[:redirect_to])
  end
end
