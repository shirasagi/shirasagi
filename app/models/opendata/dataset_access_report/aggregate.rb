module Opendata::DatasetAccessReport::Aggregate
  def self.generate(report)
    aggregate_class = "#{self}::#{report.type.classify}".constantize
    aggregate_class.new(report)
  end

  class Base
    def initialize(report)
      @report = report
    end

    def datasets
      Opendata::Dataset.site(@report.cur_site).node(@report.cur_node).allow(:read, @report.cur_user)
    end

    def csv
      csv = []
      enum_csv.each do |data|
        csv << data
      end
      csv.join
    end

    def project_pipeline
      {
        target_id: 1,
        target_class: "Opendata::Dataset",
        created: {"$add" => ["$created", Time.zone.utc_offset.in_milliseconds]}
      }
    end

    def match_pipeline
      {
        target_id: {"$in" => datasets.map(&:id).map(&:to_s)},
        target_class: "Opendata::Dataset",
        created: {"$gte" => @report.start_date, "$lt" => @report.end_date}
      }
    end

    def common_group_pipeline
      {
        _id: {
          target_id: "$target_id"
        },
        count: {"$sum" => 1}
      }
    end

    def first_line_header(ymd_header)
      [Opendata::Dataset.t("no"), nil, nil, nil, Opendata::Dataset.t("area_ids")] + ymd_header
    end

    def dataset_line_header(dataset)
      [dataset.no, dataset.name, nil, dataset.full_url, dataset.areas.pluck(:name).join("\n")]
    end

    def encode_sjis_csv(row)
      row.to_csv.encode("SJIS", invalid: :replace, undef: :replace)
    end
  end

  class Year < Base
    def enum_csv
      results = {}
      aggregate.each do |r|
        key = r["_id"]["year"].to_s
        results[key] ||= {}
        results[key][r["_id"]["target_id"].to_i] = r["count"]
      end

      dataset_ids = datasets.pluck(:id)

      Enumerator.new do |data|
        data << encode_sjis_csv(first_line_header(ymd_header))

        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil
          next unless dataset

          row = dataset_line_header(dataset)
          ymd_header.each do |year|
            key = year.to_s

            count = 0
            count += results.dig(key, dataset.id).to_i

            row << count
          end
          data << encode_sjis_csv(row)
        end
      end
    end

    def aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$created"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Recommend::History::Log.collection.aggregate(pipes)
    end

    # [2017, 2018]
    def ymd_header
      start_year = @report.start_date.year
      end_year = @report.end_date.year
      (start_year..end_year).to_a
    end
  end

  class Month < Base
    def enum_csv
      results = {}
      aggregate.each do |r|
        key = "#{r["_id"]["year"]}-#{r["_id"]["month"]}"
        results[key] ||= {}
        results[key][r["_id"]["target_id"].to_i] = r["count"]
      end

      dataset_ids = datasets.pluck(:id)

      Enumerator.new do |data|
        prev_year = nil
        months = []
        ymd_header.each do |date|
          if prev_year != date.year
            months << date.strftime("%Y年")
            prev_year = date.year
          end
          months << date.month
        end
        data << encode_sjis_csv(first_line_header(months))

        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil
          next unless dataset

          row = dataset_line_header(dataset)
          prev_year = nil
          ymd_header.each do |date|
            if prev_year != date.year
              row << nil
              prev_year = date.year
            end

            key = "#{date.year}-#{date.month}"

            count = 0
            count += results.dig(key, dataset.id).to_i

            row << count
          end
          data << encode_sjis_csv(row)
        end
      end
    end

    def aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$created"}
      group[:_id][:month] = {"$month" => "$created"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Recommend::History::Log.collection.aggregate(pipes)
    end

    # [2018-01-01, 2018-02-01, 2018-03-01..]
    def ymd_header
      (@report.start_date.to_date..@report.end_date.to_date).select { |d| d.day == 1 }
    end
  end

  class Day < Base
    def enum_csv
      results = {}
      aggregate.each do |r|
        key = "#{r["_id"]["year"]}-#{r["_id"]["month"]}-#{r["_id"]["day"]}"
        results[key] ||= {}
        results[key][r["_id"]["target_id"].to_i] = r["count"]
      end

      dataset_ids = datasets.pluck(:id)

      Enumerator.new do |data|
        prev_month = nil
        days = []
        ymd_header.each do |date|
          if prev_month != date.month
            days << date.strftime("%Y年%-m月")
            prev_month = date.month
          end
          days << date.day
        end
        data << encode_sjis_csv(first_line_header(days))

        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil
          next unless dataset

          row = dataset_line_header(dataset)
          prev_month = nil
          ymd_header.each do |date|
            if prev_month != date.month
              row << nil
              prev_month = date.month
            end

            key = "#{date.year}-#{date.month}-#{date.day}"

            count = 0
            count += results.dig(key, dataset.id).to_i

            row << count
          end
          data << encode_sjis_csv(row)
        end
      end
    end

    def aggregate
      group = common_group_pipeline
      group[:_id].merge!(
        year: {"$year" => "$created"},
        month: {"$month" => "$created"},
        day: {"$dayOfMonth" => "$created"}
      )
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Recommend::History::Log.collection.aggregate(pipes)
    end

    # [2018-01-01 00:00:00 +0900, 2018-01-02 00:00:00 +0900..]
    def ymd_header
      (@report.start_date.to_date..@report.end_date.to_date).to_a
    end
  end
end
