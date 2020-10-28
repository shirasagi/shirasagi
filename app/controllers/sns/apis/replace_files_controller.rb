class Sns::Apis::ReplaceFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::ReplaceFile

  before_action :set_item
  before_action :set_owner_item

  private

  def set_owner_item
    @owner_item = @item.owner_item
    raise "404" unless @owner_item
    @site = @owner_item.site
  end

  def render_update(result, opts = {})
    if result
      flash[:notice] = opts[:notice] if opts[:notice]
      render json: items_json, status: :ok, content_type: json_content_type
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type
    end
  end

  def items_json
    [@item, @item.thumb].compact.map do |item|
      attr = item.attributes
      attr.merge!({ "url" => item.url, "updated_to_i" => item.updated.to_i })
      attr
    end.to_json
  end

  public

  def edit
    @dst_file = SS::ReplaceTempFile.user(@cur_user).first

    raise "403" unless @owner_item.allowed?(:edit, @cur_user, site: @site)
    render
  end

  def update
    @item.attributes = get_params
    @item.in_file = SS::ReplaceTempFile.find(@item.in_file).uploaded_file
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @owner_item.allowed?(:edit, @cur_user, site: @site)

    result = @item.update
    SS::ReplaceTempFile.user(@cur_user).destroy_all if result

    render_update result, notice: "差し替え保存しました。"
  end

  def confirm
    if request.get?
      @dst_file = SS::ReplaceTempFile.user(@cur_user).first
      redirect_to({ action: :edit })unless @dst_file
      return
    end

    SS::ReplaceTempFile.user(@cur_user).destroy_all
    @item = SS::ReplaceTempFile.new get_params
    @item.cur_user = @cur_user
    render_update @item.save
  end

  def histories
    raise "403" unless @owner_item.allowed?(:read, @cur_user, site: @site)
  end

  def restore
    raise "403" unless @owner_item.allowed?(:edit, @cur_user, site: @site)
    @item = SS::HistoryFile.find(params[:source])

    render_update @item.restore, notice: "復元しました。"
  end

  def destroy
    raise "403" unless @owner_item.allowed?(:edit, @cur_user, site: @site)
    SS::HistoryFile.find(params[:source]).destroy
    render_update true
  end

  def download
    raise "403" unless @owner_item.allowed?(:read, @cur_user, site: @site)
    @item = SS::HistoryFile.find(params[:source])

    send_file @item.path, type: @item.content_type, filename: @item.download_filename,
      disposition: "attachment", x_sendfile: true
  end
end
