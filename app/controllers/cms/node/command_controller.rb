class Cms::Node::CommandController < ApplicationController
  include Cms::BaseFilter

  model Cms::Command

  navi_view "cms/node/main/navi"
  menu_view nil

  def command
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    raise "403" unless @model.allowed?(:use, @cur_user, site: @cur_site, node: @cur_node)

    @target = 'folder'
    @target_path = @cur_node.path

    return if request.get?

    output = []
    @model.site(@cur_site).allow(:use, @cur_user, site: @cur_site).order_by(order: 1, id: 1).each do |command|
      command.run(@target, @target_path)
      output << command.output
    end
    output = output.join("\n")
    respond_to do |format|
      format.html { redirect_to({ action: :command, result: output }, { notice: t('ss.notice.run') }) }
      format.json { head :no_content }
    end
  end
end
