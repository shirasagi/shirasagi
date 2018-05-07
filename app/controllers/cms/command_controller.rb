class Cms::CommandController < ApplicationController
  include Cms::BaseFilter

  model Cms::Command

  navi_view "cms/main/navi"
  menu_view nil

  def command
    raise "403" unless @model.allowed?(:use, @cur_user, site: @cur_site, node: @cur_node)

    @target = 'site'
    @target_path = @cur_site.path

    return if request.get?

    @output = []
    @model.site(@cur_site).allow(:use, @cur_user, site: @cur_site).each do |command|
      command.run(@target, @target_path)
      @output << command.output
    end
    @output = @output.join("\n")
    render
  end
end
