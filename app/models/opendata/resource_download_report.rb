class Opendata::ResourceDownloadReport
  include SS::Document
  include SS::Reference::Site

  index({ site_id: 1, year_month: 1 })

  field :year_month, type: Integer

  field :dataset_id, type: Integer
  field :dataset_name, type: String

  field :resource_id, type: Integer
  field :resource_name, type: String
  field :resource_filename, type: String

  31.times do |i|
    field "day#{i}_count", type: Integer
  end

  TARGET_YEAR_RANGE = 10

  class << self
    def start_year_options
      ey = Time.zone.today.year
      sy = ey - TARGET_YEAR_RANGE
      (sy..ey).to_a.reverse.map { |d| [ "#{d}#{I18n.t('datetime.prompts.year')}", d ] }
    end

    def start_month_options
      (1..12).to_a.map { |d| [ "#{d}#{I18n.t('datetime.prompts.month')}", d ] }
    end

    def type_options
      [:day, :month, :year].map { |t| [ I18n.t("activemodel.attributes.opendata/dataset_download_report/type.#{t}"), t ] }
    end

    def search(params)
      all.search_start(params).search_end(params).search_keyword(params)
    end

    def search_start(params)
      return all if params[:start_year].blank? || params[:start_month].blank?
      return all if !params[:start_year].numeric? || !params[:start_month].numeric?

      all.gte(year_month: params[:start_year].to_i * 100 + params[:start_month].to_i)
    end

    def search_end(params)
      return all if params[:end_year].blank? || params[:end_month].blank?
      return all if !params[:end_year].numeric? || !params[:end_month].numeric?

      all.lte(year_month: params[:end_year].to_i * 100 + params[:end_month].to_i)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in params[:keyword], :dataset_name, :resource_name
    end

    def aggregate_by_month
      project_pipeline = {
        year: { "$floor" => { "$divide" => [ "$year_month", 100 ] } },
        month: { "$mod" => [ "$year_month", 100 ] },
        dataset_id: 1,
        resource_id: 1,
        dataset_name: 1,
        resource_name: 1,
        resource_filename: 1,
        count: { "$add" => Array.new(31) { |i| { "$ifNull" => [ "$day#{i}_count", 0 ] } } }
      }

      group_pipeline = {
        _id: {
          year: "$year",
          dataset_id: "$dataset_id",
          dataset_name: "$dataset_name",
          resource_id: "$resource_id",
          resource_name: "$resource_name"
        },
        resource_filename: { "$last" => "$resource_filename" },
        count: { "$sum" => "$count" }
      }
      12.times do |i|
        group_pipeline["month#{i}_count"] = {
          "$sum" => { "$cond" => { if: { "$eq" => [ "$month", i + 1 ] }, then: "$count", else: 0 } }
        }
      end

      sort_pipeline = {
        "_id.year" => 1,
        "_id.dataset_id" => 1,
        "_id.dataset_name" => 1,
        "_id.resource_id" => 1,
        "_id.resource_name" => 1
      }

      pipes = []
      pipes << { "$match" => self.criteria.selector } if self.criteria.selector.present?
      pipes << { "$project" => project_pipeline }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => sort_pipeline }
      self.collection.aggregate(pipes).to_a
    end

    def aggregate_by_year
      now = Time.zone.now
      this_year = now.year
      min_year = this_year - TARGET_YEAR_RANGE

      project_pipeline = {
        year: { "$floor" => { "$divide" => [ "$year_month", 100 ] } },
        dataset_id: 1,
        resource_id: 1,
        dataset_name: 1,
        resource_name: 1,
        resource_filename: 1,
        count: { "$add" => Array.new(31) { |i| { "$ifNull" => [ "$day#{i}_count", 0 ] } } }
      }

      group_pipeline = {
        _id: {
          dataset_id: "$dataset_id",
          dataset_name: "$dataset_name",
          resource_id: "$resource_id",
          resource_name: "$resource_name"
        },
        resource_filename: { "$last" => "$resource_filename" },
        count: { "$sum" => "$count" }
      }
      (min_year..this_year).each do |i|
        group_pipeline["year#{i}_count"] = {
          "$sum" => { "$cond" => { if: { "$eq" => [ "$year", i.to_f ] }, then: "$count", else: 0 } }
        }
      end

      sort_pipeline = {
        "_id.dataset_id" => 1,
        "_id.dataset_name" => 1,
        "_id.resource_id" => 1,
        "_id.resource_name" => 1
      }

      pipes = []
      pipes << { "$match" => self.criteria.where("$and" => [{ :year_month.gte => min_year * 100 + 1 }]).selector }
      pipes << { "$project" => project_pipeline }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => sort_pipeline }
      self.collection.aggregate(pipes).to_a
    end
  end
end
