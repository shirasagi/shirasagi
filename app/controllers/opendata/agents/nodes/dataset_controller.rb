class Opendata::Agents::Nodes::DatasetController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter
  include Opendata::DatasetFilter
  include Opendata::AjaxFilter

  before_action :set_dataset, only: [:show_point, :add_point, :point_members]
  before_action :set_apps, only: [:show_apps]
  before_action :set_ideas, only: [:show_ideas]
  skip_filter :logged_in?

  private
    def set_dataset
      @dataset_path = Opendata::Dataset.to_dataset_path(@cur_path)
      @dataset = Opendata::Dataset.site(@cur_site).public.
        filename(@dataset_path).
        first

      raise "404" unless @dataset
    end

    def set_apps
      @dataset_app_path = Opendata::Dataset.to_dataset_path(@cur_path)

      @dataset_app = Opendata::Dataset.site(@cur_site).public.
        filename(@dataset_app_path).
        first

      raise "404" unless @dataset_app

      cond = { site_id: @cur_site.id, dataset_ids: @dataset_app.id }
      @apps = Opendata::App::App.where(cond).order_by(:updated.asc)
    end

    def set_ideas
      @dataset_idea_path = Opendata::Dataset.to_dataset_path(@cur_path)

      @dataset_idea = Opendata::Dataset.site(@cur_site).public.
        filename(@dataset_idea_path).
        first

      raise "404" unless @dataset_idea

      cond = { site_id: @cur_site.id, dataset_ids: @dataset_idea.id }
      @ideas = Opendata::Idea::Idea.where(cond).order_by(:updated.asc)
    end

  public
    def pages
      Opendata::Dataset.site(@cur_site).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}"
      @search_path    = method(:search_datasets_path)
      @rss_path       = ->(options = {}) { build_path("#{search_datasets_path}rss.xml?", options) }
      @tabs = []
      Opendata::Dataset.sort_options.each do |options|
        @tabs << { name: options[0],
                   url: "#{@search_path.call("sort" => "#{options[1]}")}",
                   pages: pages.order_by(Opendata::Dataset.sort_hash(options[1])).limit(10),
                   rss: "#{@rss_path.call("sort" => "#{options[1]}")}"}
      end

      max = 50
      @areas    = aggregate_areas(max)
      @tags     = aggregate_tags(max)
      @formats  = aggregate_formats(max)
      @licenses = aggregate_licenses(max)
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

        cond = { site_id: @cur_site.id, member_id: @cur_member.id, dataset_id: @dataset.id }
        @mode = :cancel if point = Opendata::DatasetPoint.where(cond).first
      end
    end

    def add_point
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      cond = { site_id: @cur_site.id, member_id: @cur_member.id, dataset_id: @dataset.id }

      if point = Opendata::DatasetPoint.where(cond).first
        point.destroy
        @dataset.inc point: -1
        @mode = :add
      else
        Opendata::DatasetPoint.new(cond).save
        @dataset.inc point: 1
        @mode = :cancel
      end

      render :show_point
    end

    def point_members
      @cur_node.layout = nil
      @items = Opendata::DatasetPoint.where(site_id: @cur_site.id, dataset_id: @dataset.id)
    end

    def show_apps
      @cur_node.layout = nil
    end

    def show_ideas
      @cur_node.layout = nil
      @login_mode = logged_in?(redirect: false)
      @idea_comment = Opendata::Idea::IdeaComment
    end

    def datasets_search
      @cur_node.layout = nil
      @model = Opendata::Dataset
      @items = @model.site(@cur_site).search(params[:s]).order_by(_id: -1)
    end
end
