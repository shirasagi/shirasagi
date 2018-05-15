class Cms::CommandController < ApplicationController
  include Cms::BaseFilter

  model Cms::Command

  navi_view "cms/main/navi"
  menu_view nil

  def command
    raise "403" unless @model.allowed?(:use, @cur_user, site: @cur_site, node: @cur_node)

    @commands = @model.site(@cur_site).allow(:use, @cur_user, site: @cur_site).order_by(order: 1, id: 1)
    @target = 'site'
    @target_path = @cur_site.path

    return if request.get?

    @commands.each do |command|
      command.run(@target, @target_path)
    end
    respond_to do |format|
      format.html { redirect_to({ action: :command }, { notice: t('ss.notice.run') }) }
      format.json { head :no_content }
    end
  end
end
