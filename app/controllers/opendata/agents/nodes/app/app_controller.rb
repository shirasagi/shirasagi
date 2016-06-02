class Opendata::Agents::Nodes::App::AppController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  include Opendata::App::AppFilter
  helper Opendata::UrlHelper

  before_action :set_app, only: [:download, :show_point, :add_point, :point_members, :show_executed, :add_executed, :full]
  before_action :set_ideas, only: [:show_ideas]
  before_action :set_file, only: [:app_index, :text]
  skip_filter :logged_in?

  private
    def set_app
      @app_path ||= Opendata::App.to_app_path(@cur_path)
      @app ||= Opendata::App.site(@cur_site).public.
        filename(@app_path).
        first

      raise "404" unless @app
    end

    def set_ideas
      @app_idea_path = Opendata::App.to_app_path(@cur_path)

      @app_idea = Opendata::App.site(@cur_site).public.
        filename(@app_idea_path).
        first

      raise "404" unless @app_idea

      cond = { site_id: @cur_site.id, app_ids: @app_idea.id }
      @ideas = Opendata::Idea.where(cond).order_by(:updated.asc)
    end

    def set_file
      set_app
      filename = params[:filename]
      filename.force_encoding("utf-8") if filename.present?
      filename = "index.html" if filename.blank?
      @appfile = @app.appfiles.find_by filename: filename
    end

  public
    def pages
      Opendata::App.site(@cur_site).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}"
      @search_path    = view_context.method(:search_apps_path)
      @rss_path       = ->(options = {}) { view_context.build_path("#{view_context.search_apps_path}rss.xml", options) }
      @tabs = []
      Opendata::App.sort_options.each do |options|
        if @cur_node.show_tab?(options[1])
          @tabs << { name: options[0], id: options[1],
                     url: "#{@search_path.call("sort" => "#{options[1]}")}",
                     pages: pages.order_by(Opendata::App.sort_hash(options[1])).limit(10),
                     rss: "#{@rss_path.call("sort" => "#{options[1]}")}"}
        end
      end

      max = 50
      @areas    = aggregate_areas(max)
      @tags     = aggregate_tags(max)
      @licenses = aggregate_licenses(max)
    end

    def download
      zipfilename = @app.create_zip
      send_file zipfilename, type: "application/zip", filename: "#{@app.name}.zip",
        disposition: :attachment, x_sendfile: true
    end

    def rss
      @items = pages.order_by(released: -1).limit(100)
      render_rss @cur_node, @items
    end

    def show_point
      @cur_node.layout = nil
      @mode = nil

      if logged_in?(redirect: false)
        @mode = :add

        cond = { site_id: @cur_site.id, member_id: @cur_member.id, app_id: @app.id }
        @mode = :cancel if point = Opendata::AppPoint.where(cond).first
      end
    end

    def add_point
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      cond = { site_id: @cur_site.id, member_id: @cur_member.id, app_id: @app.id }

      if point = Opendata::AppPoint.where(cond).first
        point.destroy
        @app.inc point: -1
        @mode = :add
      else
        Opendata::AppPoint.new(cond).save
        @app.inc point: 1
        @mode = :cancel
      end

      render :show_point
    end

    def point_members
      @cur_node.layout = nil
      @items = Opendata::AppPoint.where(site_id: @cur_site.id, app_id: @app.id)
    end

    def show_ideas
      @cur_node.layout = nil
      @login_mode = logged_in?(redirect: false)
      @idea_comment = Opendata::IdeaComment
    end

    def show_executed
      @cur_node.layout = nil
      # @app = Opendata::App.site(@cur_site).find(params[:app])
      @add = false
      if params[:tab_display] == "tab_html"
        @add = true
      end
      render
    end

    def add_executed
      @cur_node.layout = nil
      @add = false
      if @app.present?
        exec = @app.executed.to_i
        @app.executed = exec + 1
        res = @app.save(validate: false)
        if !res
          @app.executed = exec
        end
      end
      render :show_executed
    end

    def full
      @cur_node.layout = nil
      @item = @app
      @app_html = @item.appfiles.where(filename: "index.html").first
    end

    def app_index
      @cur_node.layout = nil
      if @appfile.present?
        send_file @appfile.file.path, type: @appfile.content_type, filename: @appfile.filename,
          disposition: :inline, x_sendfile: true
      end
    end

    def text
      @cur_node.layout = nil
      if @appfile.present?
        send_file @appfile.file.path, :type => "text/plain", filename: @appfile.filename,
          disposition: :inline, x_sendfile: true
      end
    end
end
