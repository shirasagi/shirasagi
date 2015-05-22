class Opendata::Agents::Nodes::AppController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter
  include Opendata::AppFilter

  before_action :set_app, only: [:show_point, :add_point, :point_members]
  before_action :set_ideas, only: [:show_ideas]
  skip_filter :logged_in?

  private
    def set_app
      @app_path = @cur_path.sub(/\/point\.\w+$/, ".html")

      @app = Opendata::App.site(@cur_site).public.
        filename(@app_path).
        first

      raise "404" unless @app
    end

    def set_ideas
      @app_idea_path = @cur_path.sub(/\/ideas\/.*/, ".html")

      @app_idea = Opendata::App.site(@cur_site).public.
        filename(@app_idea_path).
        first

      raise "404" unless @app_idea

      cond = { site_id: @cur_site.id, app_ids: @app_idea.id }
      @ideas = Opendata::Idea.where(cond).order_by(:updated.asc)
    end

    def create_zip(items)
      path = "#{Rails.root}/tmp/"

      zipfilename = path + items.name + ".zip"

      if File.exist?(zipfilename)
        File.unlink(zipfilename)
      end

      Zip::Archive.open(zipfilename, Zip::CREATE) do |ar|
        items.appfiles.each do |item|
          ar.add_file(item.filename, item.file.path)
        end
      end
      return zipfilename
    end

  public
    def pages
      Opendata::App.site(@cur_site).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}"
      @search_path    = method(:search_apps_path)
      @rss_path       = ->(options = {}) { build_path("#{search_apps_path}rss.xml", options) }
      @tabs = []
      Opendata::App.sort_options.each do |options|
        @tabs << { name: options[0],
                   url: "#{@search_path.call("sort" => "#{options[1]}")}",
                   pages: pages.order_by(Opendata::App.sort_hash(options[1])).limit(10),
                   rss: "#{@rss_path.call("sort" => "#{options[1]}")}"}
      end

      max = 50
      @areas    = aggregate_areas
      @tags     = aggregate_tags(max)
      @licenses = aggregate_licenses(max)
    end

    def download
      @item = Opendata::App.site(@cur_site).find(params[:app])

      zipfilename = create_zip(@item)

      send_file zipfilename, type: "application/zip", filename: "#{@item.name}.zip",
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
      @app = Opendata::App.site(@cur_site).find(params[:app])
      render
    end

    def add_executed
      @cur_node.layout = nil
      @app = Opendata::App.site(@cur_site).find(params[:app])
      if @app.present?
        exec = @app.executed.to_i
        @app.executed = exec + 1
        res = @app.save(validate: false)
        if !res
          @app.executed = exec
        end
      end
      render
    end
end
