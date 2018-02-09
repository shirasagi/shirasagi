class Gws::Memo::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Comment

  before_action :deny_with_auth
  before_action :set_item, only: [:destroy]

  navi_view "gws/memo/messages/navi"

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_cur_message
    @cur_message ||= Gws::Memo::Message.find(params[:message_id])
  end

  def fix_params
    set_cur_message
    { cur_site: @cur_site, cur_user: @cur_user, cur_message: @cur_message, text_type: 'plain' }
  end

  def set_item
    set_cur_message
    @item ||= begin
      item = @model.message(@cur_message).find(params[:id])
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
    result = @item.save
    if result
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: t('ss.notice.saved') }
        format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: @item.errors.full_messages.join('\n') }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def destroy
    raise '404' if @item.user.id != @cur_user.id

    if @item.destroy
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: t('ss.notice.deleted') }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to params[:redirect_to], notice: @item.errors.full_messages.join('\n') }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
end
