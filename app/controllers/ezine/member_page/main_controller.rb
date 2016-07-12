class Ezine::MemberPage::MainController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Ezine::Page

  append_view_path "app/views/cms/pages"
  navi_view "ezine/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      super.merge(state: 'closed')
    end

    def load_pages
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).node(@cur_node).
        allow(:read, @cur_user).
        search(params[:s]).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end

    def load_members(method = :members_to_deliver)
      @members = @cur_node.becomes_with_route.send(method).order_by(updated: -1)
      @members_email = @members.reduce("") {|a, e| a += e.email + "\n"}
    end

    def load_test_members
      load_members(:test_members_to_deliver)
    end

  public
    def index
      load_pages
    end

    def delivery_confirmation
      @crumbs << [:"ezine.deliver", action: :delivery_confirmation]

      set_item
      load_members
    end

    def delivery
      @crumbs << [:"ezine.deliver", action: :delivery_confirmation]

      page = Ezine::Page.find(params[:id])
      SS::RakeRunner.run_async "ezine:deliver", "page_id=#{page.id}"
      redirect_to({ action: :show }, { notice: t("ezine.notice.delivered") })
    end

    def delivery_test_confirmation
      @crumbs << [:"ezine.deliver_test", action: :delivery_test_confirmation]

      set_item
      load_test_members
    end

    def delivery_test
      @crumbs << [:"ezine.deliver_test", action: :delivery_test_confirmation]

      page = Ezine::Page.find(params[:id])
      page.deliver_to_test_members
      redirect_to({ action: :show }, { notice: t("ezine.notice.delivered_test") })
    end

    def sent_logs
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

      @crumbs << [:"ezine.sent_log", action: :sent_logs]

      set_item
      @items = Ezine::SentLog.where(node_id: params[:cid], page_id: params[:id]).
          order_by(created: -1).
          page(params[:page]).per(50)
    end
end
