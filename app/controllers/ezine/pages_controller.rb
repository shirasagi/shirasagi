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
      page = Ezine::Page.find(params[:id])
      require "open3"
      cmd = "bundle exec rake ezine:deliver page_id=#{page.id} &"
      stdin, stdout, stderr = Open3.popen3(cmd)
      redirect_to({ action: :delivery_confirmation }, { notice: "配信を開始しました" })
    end

    def delivery_test_confirmation
      set_item
      load_members Ezine::TestMember
    end

    def delivery_test
      page = Ezine::Page.find(params[:id])
      page.deliver_to_test_members
      redirect_to({ action: :delivery_test_confirmation }, { notice: "テスト配信を完了しました" })
    end

    def sent_logs
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

      @items = Ezine::SentLog.where(node_id: params[:cid], page_id: params[:id]).
        order_by(created: -1).
        page(params[:page]).per(50)
    end

    def preview_text
      load_pages
      item = @items.find(params[:id])
      render text: item.text.gsub(/\r\n|\r|\n/, "<br />")
    end
end
