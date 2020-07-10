require "csv"

class Inquiry::ResultsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Inquiry::Column

  append_view_path "app/views/cms/pages"
  navi_view "inquiry/main/navi"
  before_action :set_aggregation
  before_action :check_permission

  private

  def fix_params
    { cur_site: @cur_site, node_id: @cur_node.id }
  end

  def set_aggregation
    @cur_node = @cur_node.becomes_with_route
    @columns = @cur_node.columns.order_by(order: 1)
    @answer_count = @cur_node.answers.count

    options = params[:s] || {}
    options[:site] = @cur_site
    options[:node] = @cur_node
    @aggregation = @cur_node.aggregate_select_columns(options)
  end

  def check_permission
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
  end

  public

  def index
  end

  def download
    csv = CSV.generate do |data|
      data << [t("inquiry.total_count"), @answer_count]
      @columns.each do |column|
        data << []
        data << [column.name]
        if /(select|radio_button|check_box)/.match?(column.input_type)
          column.select_options.each do |opts|
            data << [opts, @aggregation[{ "column_id" => column.id, "value" => opts }]]
          end
        else
          column.answer_data(@answer_data_opts).each do |item|
            if item.value.present?
              data << [item.value]
            end
          end
        end
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
              filename: "inquiry_results_#{Time.zone.now.to_i}.csv"
  end
end
