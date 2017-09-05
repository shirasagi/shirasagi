class Chorg::ChangesetsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chorg::Changeset

  navi_view "cms/main/conf_navi"

  before_action :set_revision

  private

  def set_crumbs
    set_revision
    @crumbs << [t("chorg.revision"), chorg_revisions_revisions_path]
    @crumbs << [@cur_revision.name, edit_chorg_revisions_revision_path(id: @cur_revision.id)]
  end

  def set_item
    @item = @model.revision(set_revision).find(params[:id])
    raise "404" unless @item.type == params[:type]
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_revision
    @cur_revision ||= Chorg::Revision.site(@cur_site).where(id: params[:rid]).first
    raise "404" unless @cur_revision
    @cur_revision
  end

  def fix_params
    { cur_revision: @cur_revision, cur_type: params[:type] }
  end

  def append_view_paths
    append_view_path "app/views/chorg/changesets/#{params[:type]}"
    super
  end

  public

  def index
    redirect_to chorg_revisions_revision_path(id: params[:rid])
  end
end
