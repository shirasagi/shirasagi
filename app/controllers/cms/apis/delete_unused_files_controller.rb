class Cms::Apis::DeleteUnusedFilesController < ApplicationController
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

    raise "403" unless SS::ReplaceFile.deletable?(@owner_item, user: @cur_user, site: @cur_site, node: @cur_node)
  end

  def render_delete(result, opts = {})
    if result
      flash[:notice] = opts[:notice] if opts[:notice]
      render json: file_json, status: :ok, content_type: json_content_type
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type
    end
  end

  def file_json
    {
      id: @item.id,
      name: @item.name
    }
  end

  public

  def destroy
    result = @item.destroy
    render_delete result, notice: I18n.t('ss.notice.deleted')
  end
end
