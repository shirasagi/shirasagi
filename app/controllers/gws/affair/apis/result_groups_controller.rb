class Gws::Affair::Apis::ResultGroupsController < ApplicationController
  include Gws::ApiFilter
  include Gws::Affair::Overtime::AggregateFilter

  before_action :set_fiscal_year_month
  before_action :set_result_groups

  model Gws::Group

  def index
    @multi = params[:single].blank?
    @search_params = params[:s]
    @items = @result_groups

    if @search_params.present?
      keyword = @search_params[:keyword].to_s
      keywords = keyword.split(/[\s　]+/).uniq.compact.map { |w| /#{::Regexp.escape(w)}/i }
      keywords = keywords[0..4]

      if keywords.present?
        @items = @items.select do |item|
          keywords.select { |word| item.name =~ word }.present?
        end
        @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)
      end
    end
  end
end
