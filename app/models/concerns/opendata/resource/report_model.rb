module Opendata::Resource::ReportModel
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Reference::Site
  include Cms::SitePermission

  TARGET_YEAR_RANGE = 3

  # 削除日が不明なレコードの deleted にセットされている日時
  UNCERTAIN_DELETED_TIME = Time.at(0).in_time_zone

  included do
    index({ site_id: 1, year_month: 1 })

    set_permission_name "opendata_reports", :read

    field :year_month, type: Integer
    field :deleted, type: DateTime

    field :dataset_id, type: Integer
    field :dataset_name, type: String

    field :dataset_url, type: String
    field :dataset_areas, type: SS::Extensions::Lines
    field :dataset_categories, type: SS::Extensions::Lines
    field :dataset_estat_categories, type: SS::Extensions::Lines

    field :resource_id, type: Integer
    field :resource_name, type: String
    field :resource_filename, type: String
    field :resource_format, type: String

    31.times do |i|
      field "day#{i}_count", type: Integer
    end
  end

  module ClassMethods
    def start_year_options
      ey = Time.zone.today.year
      sy = ey - TARGET_YEAR_RANGE + 1
      (sy..ey).to_a.reverse.map { |d| [ "#{d}#{I18n.t('datetime.prompts.year')}", d ] }
    end

    def start_month_options
      (1..12).to_a.map { |d| [ "#{d}#{I18n.t('datetime.prompts.month')}", d ] }
    end

    def type_options
      [:day, :month, :year].map { |t| [ I18n.t("activemodel.attributes.opendata/dataset_download_report/type.#{t}"), t ] }
    end

    def area_options(site)
      Opendata::Node::Area.site(site).order_by(order: 1).pluck(:name)
    end

    def format_options(site)
      pipes = []
      pipes << { "$match" => self.unscoped.site(site).exists(resource_format: true).selector }
      pipes << { "$group" => { "_id" => { "$toUpper" => "$resource_format" }, "count" => { "$sum" => 1 } } }
      pipes << { "$sort" => { 'count' => -1, '_id' => 1 } }
      self.collection.aggregate(pipes).map do |data|
        format = data["_id"]
        [format, format]
      end
    end

    def search(params)
      all.search_start(params).search_end(params).search_keyword(params).search_area(params).search_format(params)
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

    def search_area(params)
      return all if params.blank? || params[:area].blank?

      all.where(dataset_areas: params[:area])
    end

    def search_format(params)
      return all if params.blank? || params[:format].blank?

      all.where(resource_format: params[:format].upcase)
    end

    def aggregate_by_month
      project_pipeline = {
        year: { "$floor" => { "$divide" => [ "$year_month", 100 ] } },
        month: { "$mod" => [ "$year_month", 100 ] },
        deleted: 1,
        dataset_id: 1,
        resource_id: 1,
        dataset_name: 1,
        resource_name: 1,
        resource_filename: 1,
        dataset_url: 1,
        dataset_areas: 1,
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
        deleted: { "$last" => "$deleted" },
        resource_filename: { "$last" => "$resource_filename" },
        dataset_url: { "$last" => "$dataset_url" },
        dataset_areas: { "$last" => "$dataset_areas" },
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
      min_year = this_year - TARGET_YEAR_RANGE + 1

      project_pipeline = {
        year: { "$floor" => { "$divide" => [ "$year_month", 100 ] } },
        deleted: 1,
        dataset_id: 1,
        resource_id: 1,
        dataset_name: 1,
        resource_name: 1,
        resource_filename: 1,
        dataset_url: 1,
        dataset_areas: 1,
        count: { "$add" => Array.new(31) { |i| { "$ifNull" => [ "$day#{i}_count", 0 ] } } }
      }

      group_pipeline = {
        _id: {
          dataset_id: "$dataset_id",
          dataset_name: "$dataset_name",
          resource_id: "$resource_id",
          resource_name: "$resource_name"
        },
        deleted: { "$last" => "$deleted" },
        resource_filename: { "$last" => "$resource_filename" },
        dataset_url: { "$last" => "$dataset_url" },
        dataset_areas: { "$last" => "$dataset_areas" },
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

    def enum_csv(site, node)
      criteria = self.all.criteria.dup
      all_ids = criteria.pluck(:id)
      prev_year_month = nil
      prev_dataset_id_name = nil

      Enumerator.new do |yielder|
        all_ids.each_slice(50) do |ids|
          items = criteria.in(id: ids).to_a
          items.each do |item|
            if prev_year_month != item.year_month
              target = Time.new(item.year_month / 100, item.year_month % 100, 1).in_time_zone
              csv_header = csv_header_for(target)
              yielder << encode_sjis_csv(csv_header)
            end

            dataset_id_name = [ item.dataset_id, item.dataset_name ].join(":")
            if prev_dataset_id_name != dataset_id_name
              dataset_header = dataset_header_for(site, node, item)
              yielder << encode_sjis_csv(dataset_header)
            end

            data = resource_csv_for(site, node, item)
            yielder << encode_sjis_csv(data)

            prev_year_month = item.year_month
            prev_dataset_id_name = dataset_id_name
          end
        end
      end
    end

    def csv_header_for(time)
      header = [
        Opendata::Dataset.t("no"), # dataset_id
        nil, # dataset_name
        nil, # resource_name
        I18n.t("ss.url"), # URL
        Opendata::Dataset.t("area_ids"), # 地域
        Opendata::Dataset.t("state") # ステータス
      ]
      header << time.strftime("%Y年%-m月")

      days = time.end_of_month.day
      days.times do |day|
        header << "#{day + 1}#{I18n.t("datetime.prompts.day")}"
      end

      header
    end

    def format_name_with_id(item_id, item_name)
      ret = ""

      if item_id.present?
        ret << "[#{item_id}]"
      end

      if item_name.present?
        ret << " " if ret.present?
        ret << item_name
      end

      ret
    end

    def dataset_header_for(_site, node, item)
      deleted = item.dataset_name.blank? || item.dataset_name.include?(I18n.t("ss.options.state.deleted"))

      [
        item.dataset_id,
        format_name_with_id(item.dataset_id, item.dataset_name),
        nil, # resource_name is always nil on dataset header
        deleted ? nil : item.dataset_url, # URL
        item.dataset_areas.present? ? item.dataset_areas.join("\n") : nil, # 地域
        deleted ? I18n.t("ss.options.state.deleted") : nil # ステータス
      ]
    end

    def resource_csv_for(_site, _node, item)
      data = [
        nil, # dataset_id
        nil, # dataset_name
        format_name_with_id(item.resource_id, item.resource_name),
        nil, # URL
        nil, # 地域
        delete_status(item.deleted), # ステータス
        nil # YYYY-MM
      ]

      target = Time.new(item.year_month / 100, item.year_month % 100, 1).in_time_zone
      days = target.end_of_month.day
      days.times do |day|
        data << (item["day#{day}_count"] || 0).to_s(:delimited)
      end

      data
    end

    def delete_status(time)
      return if time.blank?

      time = time.in_time_zone
      if time == UNCERTAIN_DELETED_TIME
        I18n.t("ss.options.state.deleted")
      else
        "削除: #{I18n.l(time.to_date)}"
      end
    end

    def encode_sjis_csv(array)
      array.to_csv.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def enum_monthly_csv(site, node, aggregation_results)
      prev_year = nil
      prev_dataset_id_name = nil

      Enumerator.new do |yielder|
        aggregation_results.each do |result|
          year = result["_id"]["year"].to_i
          if prev_year != year
            target = Time.new(year, 1, 1).in_time_zone
            csv_header = monthly_csv_header_for(target)
            yielder << encode_sjis_csv(csv_header)
          end

          dataset_id_name = [ result["_id"]["dataset_id"], result["_id"]["dataset_name"] ].join(":")
          if prev_dataset_id_name != dataset_id_name
            dataset_header = monthly_dataset_header_for(site, node, result)
            yielder << encode_sjis_csv(dataset_header)
          end

          data = monthly_resource_csv_for(site, node, result)
          yielder << encode_sjis_csv(data)

          prev_year = year
          prev_dataset_id_name = dataset_id_name
        end
      end
    end

    def monthly_csv_header_for(time)
      header = [
        Opendata::Dataset.t("no"), # dataset_id
        nil, # dataset_name
        nil, # resource_name
        I18n.t("ss.url"), # URL
        Opendata::Dataset.t("area_ids"), # 地域
        Opendata::Dataset.t("state") # ステータス
      ]
      header << time.strftime("%Y年")

      12.times do |month|
        header << "#{month + 1}#{I18n.t("datetime.prompts.month")}"
      end

      header
    end

    def monthly_dataset_header_for(_site, node, result)
      dataset_name = result["_id"]["dataset_name"]
      deleted = dataset_name.blank? || dataset_name.include?(I18n.t("ss.options.state.deleted"))

      [
        result["_id"]["dataset_id"],
        format_name_with_id(result["_id"]["dataset_id"], dataset_name),
        nil, # resource_name is always nil on dataset header
        deleted ? nil : result["dataset_url"].presence || dataset_url(node, result["_id"]["dataset_id"]), # URL
        result["dataset_areas"].present? ? result["dataset_areas"].join("\n") : nil, # 地域
        deleted ? I18n.t("ss.options.state.deleted") : nil # ステータス
      ]
    end

    def monthly_resource_csv_for(site, node, result)
      resource_name = result["_id"]["resource_name"]
      resource_id = result["_id"]["resource_id"]

      data = [
        nil, # dataset_id
        nil, # dataset_name
        format_name_with_id(resource_id, resource_name),
        nil, # URL
        nil, # 地域
        delete_status(result["deleted"]), # ステータス
        nil # YYYY
      ]

      12.times do |month|
        data << (result["month#{month}_count"] || 0).to_s(:delimited)
      end

      data
    end

    def enum_yearly_csv(site, node, aggregation_results)
      prev_dataset_id_name = nil

      Enumerator.new do |yielder|
        yielder << encode_sjis_csv(yearly_csv_header_for)

        aggregation_results.each do |result|
          dataset_id_name = [ result["_id"]["dataset_id"], result["_id"]["dataset_name"] ].join(":")
          if prev_dataset_id_name != dataset_id_name
            dataset_header = yearly_dataset_header_for(site, node, result)
            yielder << encode_sjis_csv(dataset_header)
          end

          data = yearly_resource_csv_for(site, node, result)
          yielder << encode_sjis_csv(data)

          prev_dataset_id_name = dataset_id_name
        end
      end
    end

    def yearly_csv_header_for
      header = [
        Opendata::Dataset.t("no"), # dataset_id
        nil, # dataset_name
        nil, # resource_name
        I18n.t("ss.url"), # URL
        Opendata::Dataset.t("area_ids"), # 地域
        Opendata::Dataset.t("state") # ステータス
      ]

      ey = Time.zone.today.year
      sy = ey - TARGET_YEAR_RANGE + 1
      (sy..ey).each do |year|
        header << "#{year}#{I18n.t("datetime.prompts.year")}"
      end

      header
    end

    alias yearly_dataset_header_for monthly_dataset_header_for

    def yearly_resource_csv_for(site, node, result)
      resource_name = result["_id"]["resource_name"]
      resource_id = result["_id"]["resource_id"]

      data = [
        nil, # dataset_id
        nil, # dataset_name
        format_name_with_id(resource_id, resource_name),
        nil, # URL
        nil, # 地域
        delete_status(result["deleted"]), # ステータス
      ]

      ey = Time.zone.today.year
      sy = ey - TARGET_YEAR_RANGE + 1
      (sy..ey).each do |year|
        data << (result["year#{year}_count"] || 0).to_s(:delimited)
      end

      data
    end
  end
end
