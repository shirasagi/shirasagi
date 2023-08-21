class Gws::Share::Apis::FolderCrudController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Share::Folder
  navi_view nil
  menu_view nil
  layout "ss/ajax"

  private

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def set_parent
    if params.key?(:parent_id)
      @parent = @model.find(params[:parent_id])
    end
  end

  def render_change(result, opts = {})
    if !result
      render_update result, opts
      return
    end

    location = opts[:location].presence || crud_redirect_url || { action: :show }
    notice = opts[:notice].presence || t("ss.notice.saved")

    respond_to do |format|
      format.html { redirect_to location, notice: notice }
      format.json { render json: @item.to_json, content_type: json_content_type }
    end
  end

  public

  def new
    set_parent
    if @parent
      allowed = @parent.allowed?(:edit, @cur_user, site: @cur_site)
    else
      allowed = @model.allowed?(:edit, @cur_user, site: @cur_site)
    end
    raise "403" unless allowed

    @addons = []
    render template: "new"
  end

  def create
    set_parent
    if @parent
      allowed = @parent.allowed?(:edit, @cur_user, site: @cur_site)
    else
      allowed = @model.allowed?(:edit, @cur_user, site: @cur_site)
    end
    raise "403" unless allowed

    @item = @model.new get_params
    @item.attributes["action"] = "create"
    @item.group_ids = [ @cur_group.id ]
    if @parent.present?
      @item.in_parent = @parent.id
      @item.share_max_file_size = @parent.share_max_file_size
      @item.share_max_folder_size = @parent.share_max_folder_size
      @item.readable_setting_range = @parent.readable_setting_range
      @item.readable_custom_group_ids = @parent.readable_custom_group_ids
      @item.readable_group_ids = @parent.readable_group_ids
      @item.readable_member_ids = @parent.readable_member_ids
      @item.group_ids = (@item.group_ids + @parent.group_ids).uniq
      @item.user_ids = (@item.user_ids + @parent.user_ids).uniq
    end
    render_create @item.save
  end

  def rename
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.in_basename = ::File.basename(@item.name)
    @parent = @item.parent
    @addons = []
    render template: "edit"
  end

  def update
    set_item
    save_name = @item.name
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    @item.in_parent = @item.parent.id if @item.parent.present?
    # be careful, Gws::Share::Folder has many required magic flags to work properly
    @item.attributes["before_folder_name"] = save_name
    @item.attributes["controller"] = "gws/share/folders"
    @item.attributes["action"] = "update"
    render_change @item.save
  end

  def delete
    set_item
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    render template: "delete"
  end

  def destroy
    set_item
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    @item.attributes["action"] = "destroy"
    render_destroy @item.destroy
  end
end
