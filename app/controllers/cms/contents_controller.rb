class Cms::ContentsController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.shortcut"), action: :index]
  end

  public

  def index
    @model = Cms::Node
    self.menu_view_file = nil

    @s = Cms::ShortcutComponent::SearchParams.new
    @s = @s.with(mod: params[:mod]) if params[:mod].present?
    @s = @s.with(keyword: params.dig(:s, :keyword)) if params.dig(:s, :keyword).present?

    respond_to do |format|
      format.html { render }
      # 高速化により JSON には応答不能になった
      format.json { head :not_found }
    end
  end
end
