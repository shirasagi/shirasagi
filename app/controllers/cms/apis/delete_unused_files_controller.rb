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

    raise "403" unless SS::ReplaceFile.replaceable?(@owner_item, user: @cur_user, site: @cur_site, node: @cur_node)
  end

  public

  def destroy
    if @item.destroy
      Rails.logger.debug{ "Successfully destroyed item with ID: #{@item.id}" }
      flash[:notice] = I18n.t('ss.notice.deleted')
    else
      Rails.logger.error{ "Failed to destroy item with ID: #{@item.id}. Errors: #{@item.errors.full_messages.join(', ')}" }
      flash.now[:notice] = "#{t("ss.notice.unable_to_delete")} #{@item.errors.full_messages.join(', ')}"
    end
    redirect_back fallback_location: root_path
  end
end
