class Gws::Notice::Frames::FoldersTreesController < ApplicationController
  include Gws::BaseFilter

  model Gws::Notice::Folder

  private

  def component_class
    @component_class ||= begin
      # キャッシュを利かせたいのでモード毎にクラスを分ける
      case params[:mode].to_s.presence
      when 'editable'
        Gws::Notice::FoldersTreeComponent::Editable
      when 'readable'
        Gws::Notice::FoldersTreeComponent::Readable
      when 'back_number'
        Gws::Notice::FoldersTreeComponent::BackNumber
      when 'calendar'
        Gws::Notice::FoldersTreeComponent::Calendar
      else
        raise "404"
      end
    end
  end

  public

  def index
    component = component_class.new(cur_site: @cur_site, cur_user: @cur_user)
    render component, layout: false
  end

  def super_reload
    component = component_class.new(cur_site: @cur_site, cur_user: @cur_user, cache_mode: "refresh")
    render component, layout: false
  end
end
