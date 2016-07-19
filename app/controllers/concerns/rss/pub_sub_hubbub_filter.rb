module Rss::PubSubHubbubFilter
  extend ActiveSupport::Concern

  included do
    model Rss::Page
    append_view_path "app/views/cms/pages"
    navi_view "rss/main/navi"
    before_action :convert_cur_node
  end

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def convert_cur_node
      save = @cur_node
      @cur_node = @cur_node.becomes_with_route rescue save if @cur_node.present?
    end

  public
    def subscribe
      unless request.post?
        return
      end

      @item.subscribe
      redirect_to action: :index
    end

    def unsubscribe
      unless request.delete?
        return
      end

      @item.unsubscribe
      redirect_to action: :index
    end
end
