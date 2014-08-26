# coding: utf-8
module  Event::Nodes::Page
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Event::Node::Page
  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include Event::EventHelper
    helper Event::EventHelper

    public
      # for tabs
      def pages
        Cms::Page.site(@cur_site).public.
          where(@cur_node.condition_hash).
          where(:"event_dates.0".exists => true)
      end

      def index
        if params[:year].present? && params[:month].present?
          if Date.valid_date?(params[:year].to_i, params[:month].to_i, 1)
            @year  = params[:year].to_i
            @month = params[:month].to_i
          end
        elsif params[:year].blank? && params[:month].blank?
          @year  = Date.today.year.to_i
          @month = Date.today.month.to_i
        end

        if @year && @month && within_one_year?(Date.new(@year, @month, 1))
          index_monthly
        else
          raise "404"
        end
      end

    private
      def index_monthly
        @events = {}
        start_date = Date.new(@year, @month, 1)
        close_date = @month != 12 ? Date.new(@year, @month + 1, 1) : Date.new(@year + 1, 1, 1)

        (start_date...close_date).each do |d|
          @events[d] = Cms::Page.site(@cur_site).
            where(@cur_node.condition_hash).
            where(:"event_dates".in => [d.mongoize]).
            entries.
            sort_by{ |page| page.event_dates.size }
        end
        render
      end
  end
end
