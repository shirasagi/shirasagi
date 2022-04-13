class Cms::Apis::ReplaceFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::ReplaceFile

  before_action :set_item
  before_action :set_owner_item
  before_action :deny_sanitizing_file

  private

  def set_owner_item
    @owner_item = @item.owner_item
    raise "404" unless @owner_item
    raise "404" unless @owner_item.id.to_s == params[:owner_item_id].to_s

    raise "403" unless SS::ReplaceFile.replaceable?(@owner_item, user: @cur_user, site: @cur_site, node: @cur_node)
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
    [ @item, @item.thumb ].select { |item| Fs.file?(item.path) }.map do |item|
      {
        name: item.name,
        filename: item.filename,
        content_type: item.content_type,
        size: item.size,
        url: item.url,
        updated_to_i: item.updated.to_i,
      }
    end.to_json
  end

  public

  def edit
    @dst_file = SS::ReplaceTempFile.user(@cur_user).first

    render
  end

  def update
    @item.attributes = get_params
    @item.in_file = SS::ReplaceTempFile.find(@item.in_file).uploaded_file
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    result = @item.update
    SS::ReplaceTempFile.user(@cur_user).destroy_all if result

    render_update result, notice: I18n.t('ss.notice.replace_saved')
  end

  def confirm
    if request.get? || request.head?
      @dst_file = SS::ReplaceTempFile.user(@cur_user).first
      redirect_to({ action: :edit }) unless @dst_file
      return
    end

    SS::ReplaceTempFile.user(@cur_user).destroy_all
    @item = SS::ReplaceTempFile.new get_params
    @item.cur_user = @cur_user
    render_update @item.save
  end

  def histories
  end

  def restore
    @item = SS::HistoryFile.find(params[:source])

    render_update @item.restore, notice: I18n.t('history.notice.restored')
  end

  def destroy
    SS::HistoryFile.find(params[:source]).destroy
    render_update true
  end

  def download
    @item = SS::HistoryFile.find(params[:source])

    send_file @item.path, type: @item.content_type, filename: @item.download_filename,
      disposition: "attachment", x_sendfile: true
  end
end
