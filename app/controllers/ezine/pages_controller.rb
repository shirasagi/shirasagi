class Ezine::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Ezine::Page

  append_view_path "app/views/cms/pages"
  navi_view "ezine/main/navi"

  private
  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def load_pages
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).node(@cur_node).
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).per(50)
  end

  def load_members(model)
    @members = model.site(@cur_site).order_by(updated: -1)
    @members_email = @members.reduce("") {|a, e| a += e.email + "\n"}
  end

  public
    def index
      load_pages
    end

    def delivery_confirmation
      set_item
      load_members Ezine::Member
    end

    def delivery
      #TODO: メールの送信処理を追加する
      render text: "delivery OK" + params.to_s
    end

    def delivery_test_confirmation
      set_item
      load_members Ezine::TestMember
    end

    def delivery_test
      #TODO: メールの送信処理を追加する
      render text: "delivery test OK" + params.to_s
    end
end
