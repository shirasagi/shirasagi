class Gws::Chorg::ChangesetsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view 'gws/main/conf_navi'
  model Gws::Chorg::Changeset
  append_view_path 'app/views/chorg/changesets'

  before_action :set_revision

  private

  def set_crumbs
    set_revision
    @crumbs << [t('modules.gws/chorg'), gws_chorg_revisions_path]
    @crumbs << [@cur_revision.name, gws_chorg_revision_path(id: @cur_revision.id)]
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
    @cur_revision ||= Gws::Chorg::Revision.site(@cur_site).where(id: params[:rid]).first
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
    redirect_to gws_chorg_revision_path(id: params[:rid])
  end
end
