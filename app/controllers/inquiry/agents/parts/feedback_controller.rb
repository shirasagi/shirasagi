class Inquiry::Agents::Parts::FeedbackController < ApplicationController
  include Cms::PartFilter::View

  before_action :set_parent
  before_action :set_columns
  before_action :set_answer

  private
    def set_parent
      @cur_parent ||= @cur_part.parent
      @cur_parent = @cur_parent.becomes_with_route
    end

    def set_columns
      @columns = Inquiry::Column.site(@cur_site).
        where(node_id: @cur_parent.id, state: "public").
        order_by(order: 1)
    end

    def set_answer
      @items = []
      @data = {}
      @columns.each do |column|
        @items << [column, params[:item].try(:[], column.id.to_s)]
        @data[column.id] = [params[:item].try(:[], column.id.to_s)]
        if column.input_confirm == "enabled"
          @items.last << params[:item].try(:[], "#{column.id}_confirm")
          @data[column.id] << params[:item].try(:[], "#{column.id}_confirm")
        end
      end
      @answer = Inquiry::Answer.new(cur_site: @cur_site, cur_node: @cur_parent)
      @answer.remote_addr = request.env["HTTP_X_REAL_IP"] || request.remote_ip
      @answer.user_agent = request.user_agent
      @answer.set_data(@data)
    end

  public
    def index
    end
end
