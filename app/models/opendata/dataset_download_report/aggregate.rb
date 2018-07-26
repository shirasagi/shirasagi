module Opendata::DatasetDownloadReport::Aggregate
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
        dataset_id: 1,
        resource_id: 1,
        downloaded: {"$add" => ["$downloaded", Time.zone.utc_offset.in_milliseconds]}
      }
    end

    def match_pipeline
      {
        dataset_id: {"$in" => datasets.map(&:id)},
        downloaded: {"$gte" => @report.start_date, "$lt" => @report.end_date}
      }
    end

    def common_group_pipeline
      {
        _id: {
          dataset_id: "$dataset_id",
          resource_id: "$resource_id"
        },
        count: {"$sum" => 1}
      }
    end

    def first_line_header(ymd_header)
      [nil, nil, nil] + ymd_header
    end

    def dataset_line_header(dataset)
      [dataset.name, nil, dataset.full_url]
    end

    def resource_line_header(resource)
      [nil, resource.filename, nil]
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
        results[key][r["_id"]["dataset_id"]] ||= {}
        results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
      end

      bulk_results = {}
      bulk_aggregate.each do |r|
        key = r["_id"]["year"].to_s
        bulk_results[key] ||= {}
        bulk_results[key][r["_id"]["dataset_id"]] ||= {}
        bulk_results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
      end

      dataset_results = {}
      dataset_aggregate.each do |r|
        key = r["_id"]["year"].to_s
        dataset_results[key] ||= {}
        dataset_results[key][r["_id"]["dataset_id"]] ||= {}
        dataset_results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
      end

      dataset_ids = datasets.pluck(:id)

      Enumerator.new do |data|
        data << encode_sjis_csv(first_line_header(ymd_header))

        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil
          next unless dataset

          data << encode_sjis_csv(dataset_line_header(dataset))

          resources = dataset.resources.to_a
          resources.each do |resource|
            row = resource_line_header(resource)
            ymd_header.each do |year|
              key = year.to_s

              count = 0
              count += results.dig(key, dataset.id, resource.id).to_i
              count += bulk_results.dig(key, dataset.id, resource.id).to_i
              count += dataset_results.dig(key, dataset.id, resource.id).to_i

              row << count
            end
            data << encode_sjis_csv(row)
          end
        end
      end
    end

    def aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$downloaded"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Opendata::ResourceDownloadHistory.collection.aggregate(pipes)
    end

    def bulk_aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$downloaded"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Opendata::ResourceBulkDownloadHistory.collection.aggregate(pipes)
    end

    def dataset_aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$downloaded"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Opendata::ResourceDatasetDownloadHistory.collection.aggregate(pipes)
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
        results[key][r["_id"]["dataset_id"]] ||= {}
        results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
      end

      bulk_results = {}
      bulk_aggregate.each do |r|
        key = "#{r["_id"]["year"]}-#{r["_id"]["month"]}"
        bulk_results[key] ||= {}
        bulk_results[key][r["_id"]["dataset_id"]] ||= {}
        bulk_results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
      end

      dataset_results = {}
      dataset_aggregate.each do |r|
        key = "#{r["_id"]["year"]}-#{r["_id"]["month"]}"
        dataset_results[key] ||= {}
        dataset_results[key][r["_id"]["dataset_id"]] ||= {}
        dataset_results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
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

          data << encode_sjis_csv(dataset_line_header(dataset))

          resources = dataset.resources.to_a
          resources.each do |resource|
            row = resource_line_header(resource)
            prev_year = nil
            ymd_header.each do |date|
              if prev_year != date.year
                row << nil
                prev_year = date.year
              end

              key = "#{date.year}-#{date.month}"

              count = 0
              count += results.dig(key, dataset.id, resource.id).to_i
              count += bulk_results.dig(key, dataset.id, resource.id).to_i
              count += dataset_results.dig(key, dataset.id, resource.id).to_i

              row << count
            end
            data << encode_sjis_csv(row)
          end
        end
      end
    end

    def aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$downloaded"}
      group[:_id][:month] = {"$month" => "$downloaded"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      results = Opendata::ResourceDownloadHistory.collection.aggregate(pipes)
    end

    def bulk_aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$downloaded"}
      group[:_id][:month] = {"$month" => "$downloaded"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      results = Opendata::ResourceBulkDownloadHistory.collection.aggregate(pipes)
    end

    def dataset_aggregate
      group = common_group_pipeline
      group[:_id][:year] = {"$year" => "$downloaded"}
      group[:_id][:month] = {"$month" => "$downloaded"}
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      results = Opendata::ResourceDatasetDownloadHistory.collection.aggregate(pipes)
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
        results[key][r["_id"]["dataset_id"]] ||= {}
        results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
      end

      bulk_results = {}
      bulk_aggregate.each do |r|
        key = "#{r["_id"]["year"]}-#{r["_id"]["month"]}-#{r["_id"]["day"]}"
        bulk_results[key] ||= {}
        bulk_results[key][r["_id"]["dataset_id"]] ||= {}
        bulk_results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
      end

      dataset_results = {}
      dataset_aggregate.each do |r|
        key = "#{r["_id"]["year"]}-#{r["_id"]["month"]}-#{r["_id"]["day"]}"
        dataset_results[key] ||= {}
        dataset_results[key][r["_id"]["dataset_id"]] ||= {}
        dataset_results[key][r["_id"]["dataset_id"]][r["_id"]["resource_id"]] = r["count"]
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

          data << encode_sjis_csv(dataset_line_header(dataset))

          resources = dataset.resources.to_a
          resources.each do |resource|
            row = resource_line_header(resource)
            prev_month = nil
            ymd_header.each do |date|
              if prev_month != date.month
                row << nil
                prev_month = date.month
              end

              key = "#{date.year}-#{date.month}-#{date.day}"

              count = 0
              count += results.dig(key, dataset.id, resource.id).to_i
              count += bulk_results.dig(key, dataset.id, resource.id).to_i
              count += dataset_results.dig(key, dataset.id, resource.id).to_i

              row << count
            end
            data << encode_sjis_csv(row)
          end
        end
      end
    end

    def aggregate
      group = common_group_pipeline
      group[:_id].merge!(
        year: {"$year" => "$downloaded"},
        month: {"$month" => "$downloaded"},
        day: {"$dayOfMonth" => "$downloaded"}
      )
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Opendata::ResourceDownloadHistory.collection.aggregate(pipes)
    end

    def bulk_aggregate
      group = common_group_pipeline
      group[:_id].merge!(
        year: {"$year" => "$downloaded"},
        month: {"$month" => "$downloaded"},
        day: {"$dayOfMonth" => "$downloaded"}
      )
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Opendata::ResourceBulkDownloadHistory.collection.aggregate(pipes)
    end

    def dataset_aggregate
      group = common_group_pipeline
      group[:_id].merge!(
        year: {"$year" => "$downloaded"},
        month: {"$month" => "$downloaded"},
        day: {"$dayOfMonth" => "$downloaded"}
      )
      pipes = []
      pipes << {"$project" => project_pipeline}
      pipes << {"$match" => match_pipeline}
      pipes << {"$group" => group}
      Opendata::ResourceDatasetDownloadHistory.collection.aggregate(pipes)
    end

    # [2018-01-01 00:00:00 +0900, 2018-01-02 00:00:00 +0900..]
    def ymd_header
      (@report.start_date.to_date..@report.end_date.to_date).to_a
    end
  end
end
