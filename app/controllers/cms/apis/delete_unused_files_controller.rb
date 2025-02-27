class Cms::Apis::DeleteUnusedFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::File

  before_action :set_item
  before_action :set_owner_item
  before_action :deny_sanitizing_file

  private

  def set_item
    @item = SS::File.find(params[:id])
  end

  def set_owner_item
    @owner_item = @item.owner_item
    raise "404" unless @owner_item
    raise "404" unless @owner_item.id.to_s == params[:owner_item_id].to_s

    raise "403" unless SS::ReplaceFile.replaceable?(@owner_item, user: @cur_user, site: @cur_site, node: @cur_node)
  end

  def items_json
    [ @item, @item.thumb ].select { |item| Fs.file?(item.path) }.map do |item|
      {}
    end.to_json
  end

  def render_update(result, opts = {})
    if result
      flash[:notice] = opts[:notice] if opts[:notice]
      render json: items_json, status: :ok, content_type: json_content_type
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type
    end
  end

  public

  def delete
    render :delete
  end

  def destroy
    result = @item.destroy
    if result
      Rails.logger.debug{ "Successfully destroyed item with ID: #{@item.id}" }
      render_update result, notice: t('ss.notice.deleted')
    else
      Rails.logger.error { "Failed to destroy item with ID: #{@item.id}" }
      render_update result
    end
  end
end
