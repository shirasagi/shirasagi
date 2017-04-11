class Cms::Node::ImportController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::ImportJobFile

  navi_view "cms/node/import/navi"
  menu_view nil

  def import
    return if request.get?

    @item = @model.new get_params
    render_create @item.save_with_import, location: { action: :import }, render: { file: :import }, notice: t("views.notice.import")
  end

  private
    def fix_params
      { cur_site: @cur_site, cur_node: @cur_node, cur_user: @cur_user }
    end
end
