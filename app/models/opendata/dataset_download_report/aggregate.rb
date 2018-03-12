module Opendata::DatasetDownloadReport::Aggregate
  def self.generate_csv(report)
    aggregate_class = "#{self}::#{report.type.classify}".constantize
    aggregate_class.new(report).csv
  end

  class Base
    def initialize(report)
      @report = report
    end

    def datasets
      Opendata::Dataset.site(@report.cur_site).node(@report.cur_node).allow(:read, @report.cur_user)
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
  end

  class Year < Base
    def csv
      results = aggregate.map(&:to_h)

      CSV.generate do |data|
        data << first_line_header(ymd_header)

        datasets.each do |dataset|
          data << dataset_line_header(dataset)

          dataset.resources.each do |resource|
            row = resource_line_header(resource)
            ymd_header.each do |year|
              result = results.find do |r|
                r.extract_id == {
                  "dataset_id" => dataset.id,
                  "resource_id" => resource.id,
                  "year" => year
                }
              end
              row.push(result.try(:[], "count") || 0)
            end
            data << row
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

    # [2017, 2018]
    def ymd_header
      start_year = @report.start_date.year
      end_year = @report.end_date.year
      (start_year..end_year).to_a
    end
  end

  class Month < Base
    def csv
      results = aggregate.map(&:to_h)

      CSV.generate do |data|
        prev_year = nil
        months = []
        ymd_header.each do |date|
          if prev_year != date.year
            months << date.strftime("%Y年")
            prev_year = date.year
          end
          months << date.month
        end
        data << first_line_header(months)

        datasets.each do |dataset|
          data << dataset_line_header(dataset)

          dataset.resources.each do |resource|
            row = resource_line_header(resource)
            prev_year = nil
            ymd_header.each do |date|
              if prev_year != date.year
                row << nil
                prev_year = date.year
              end

              result = results.find do |r|
                r.extract_id == {
                  "dataset_id" => dataset.id,
                  "resource_id" => resource.id,
                  "year" => date.year,
                  "month" => date.month
                }
              end
              row.push(result.try(:[], "count") || 0)
            end
            data << row
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

    # [2018-01-01, 2018-02-01, 2018-03-01..]
    def ymd_header
      (@report.start_date.to_date..@report.end_date.to_date).select { |d| d.day == 1 }
    end
  end

  class Day < Base
    def csv
      results = aggregate.map(&:to_h)

      CSV.generate do |data|
        prev_month = nil
        days = []
        ymd_header.each do |date|
          if prev_month != date.month
            days << date.strftime("%Y年%-m月")
            prev_month = date.month
          end
          days << date.day
        end
        data << first_line_header(days)

        datasets.each do |dataset|
          data << dataset_line_header(dataset)

          dataset.resources.each do |resource|
            row = resource_line_header(resource)
            prev_month = nil
            ymd_header.each do |date|
              if prev_month != date.month
                row << nil
                prev_month = date.month
              end

              result = results.find do |r|
                r.extract_id == {
                  "dataset_id" => dataset.id,
                  "resource_id" => resource.id,
                  "year" => date.year,
                  "month" => date.month,
                  "day" => date.day
                }
              end
              row.push(result.try(:[], "count") || 0)
            end
            data << row
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

    # [2018-01-01 00:00:00 +0900, 2018-01-02 00:00:00 +0900..]
    def ymd_header
      (@report.start_date.to_date..@report.end_date.to_date).to_a
    end
  end
end
