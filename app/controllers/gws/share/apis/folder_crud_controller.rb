class Gws::Share::Apis::FolderCrudController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Share::Folder
  navi_view nil
  menu_view nil
  layout "ss/ajax"

  def new
    @addons = []
    if params.key?(:parent_id)
      @parent = @model.find(params[:parent_id])
    end
    render file: "new"
  end

  def create
    if params.key?(:parent_id)
      @parent = @model.find(params[:parent_id])
    end

    @item = @model.new get_params
    @item.in_parent = @parent if @parent.present?
    @item.group_ids = [ @cur_group.id ]
    render_create @item.save
  end

  # def new_sub
  #   set_item
  #   render file: "new"
  # end
  #
  # def create_sub
  #   set_item
  # end

  def rename
    set_item
    @item.in_basename = ::File.basename(@item.name)
    @parent = @item.parent
    @addons = []
    render file: "edit"
  end

  def update
    set_item
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    return render_update(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def delete
    set_item
    render file: "delete"
  end

  def destroy
    set_item
  end
end
