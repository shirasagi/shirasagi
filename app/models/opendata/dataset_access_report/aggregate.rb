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
        site_id: 1,
        target_id: 1,
        target_class: "Opendata::Dataset",
        created: {"$add" => ["$created", Time.zone.utc_offset.in_milliseconds]}
      }
    end

    def match_pipeline
      {
        site_id: @report.cur_site.id,
        target_class: "Opendata::Dataset",
        created: {"$gte" => @report.start_date, "$lt" => @report.end_date}
      }
    end

    def group_pipeline
      {
        _id: {
          target_id: "$target_id"
        },
        count: {"$sum" => 1}
      }
    end

    def aggregate
      pipes = []
      pipes << { "$project" => project_pipeline }
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }
      Recommend::History::Log.collection.aggregate(pipes)
    end

    def first_line_header(ymd_header)
      [
        Opendata::Dataset.t("no"),
        nil,
        nil,
        I18n.t("ss.url"),
        Opendata::Dataset.t("area_ids"),
        Opendata::Dataset.t("state")
      ] + ymd_header
    end

    def dataset_line_header(dataset, history)
      if dataset
        no = dataset.no
        name = "[#{history[:id]}] #{dataset.name}"
        full_url = dataset.full_url
        state = nil
        areas = dataset.areas.order_by(order: 1).pluck(:name).join("\n")
      else
        no = history[:id]
        name = "[#{history[:id]}][#{I18n.t("ss.options.state.deleted")}] #{history[:name]}"
        full_url = nil
        state = I18n.t("ss.options.state.deleted")
        areas = nil
      end

      [no, name, nil, full_url, areas, state]
    end

    def set_result(result)
      year = result["_id"]["year"]
      month = result["_id"]["month"]
      day = result["_id"]["day"]
      dataset_id = result["_id"]["target_id"].to_i

      count = result["count"]
      key = [year, month, day].compact.join("-")

      @counts ||= {}
      @counts[dataset_id] ||= {}
      @counts[dataset_id][key] = @counts[dataset_id][key].to_i + count

      @history_datasets ||= {}
      @history_datasets[dataset_id] ||= {}
      @history_datasets[dataset_id][:id] ||= dataset_id
    end

    def encode_sjis_csv(row)
      row.to_csv.encode("SJIS", invalid: :replace, undef: :replace)
    end
  end

  class Year < Base
    def enum_csv
      aggregate.each { |result| set_result(result) }
      dataset_ids = @counts.keys.sort

      Enumerator.new do |data|
        data << encode_sjis_csv(first_line_header(ymd_header.map { |y| "#{y}#{I18n.t("datetime.prompts.year")}" }))

        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil

          row = dataset_line_header(dataset, @history_datasets[dataset_id])
          ymd_header.each do |year|
            key = year.to_s
            row << @counts.dig(dataset_id, key).to_i
          end
          data << encode_sjis_csv(row)
        end
      end
    end

    def group_pipeline
      group = super
      group[:_id][:year] = { "$year" => "$created" }
      group
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
      aggregate.each { |result| set_result(result) }
      dataset_ids = @counts.keys.sort

      Enumerator.new do |data|
        prev_year = nil
        months = []
        ymd_header.each do |date|
          if prev_year != date.year
            months << date.strftime("%Y年")
            prev_year = date.year
          end
          months << "#{date.month}#{I18n.t("datetime.prompts.month")}"
        end
        data << encode_sjis_csv(first_line_header(months))

        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil

          row = dataset_line_header(dataset, @history_datasets[dataset_id])
          data << encode_sjis_csv(row)

          prev_year = nil
          ymd_header.each do |date|
            if prev_year != date.year
              row << nil
              prev_year = date.year
            end

            key = "#{date.year}-#{date.month}"
            row << @counts.dig(dataset_id, key).to_i
          end
          data << encode_sjis_csv(row)
        end
      end
    end

    def group_pipeline
      group = super
      group[:_id][:year] = { "$year" => "$created" }
      group[:_id][:month] = { "$month" => "$created" }
      group
    end

    # [2018-01-01, 2018-02-01, 2018-03-01..]
    def ymd_header
      (@report.start_date.to_date..@report.end_date.to_date).select { |d| d.day == 1 }
    end
  end

  class Day < Base
    def enum_csv
      aggregate.each { |result| set_result(result) }
      dataset_ids = @counts.keys.sort

      Enumerator.new do |data|
        prev_month = nil
        days = []
        ymd_header.each do |date|
          if prev_month != date.month
            days << date.strftime("%Y年%-m月")
            prev_month = date.month
          end
          days << "#{date.day}#{I18n.t("datetime.prompts.day")}"
        end
        data << encode_sjis_csv(first_line_header(days))

        dataset_ids.each do |dataset_id|
          dataset = Opendata::Dataset.find(dataset_id) rescue nil

          row = dataset_line_header(dataset, @history_datasets[dataset_id])
          prev_month = nil
          ymd_header.each do |date|
            if prev_month != date.month
              row << nil
              prev_month = date.month
            end

            key = "#{date.year}-#{date.month}-#{date.day}"
            row << @counts.dig(dataset_id, key).to_i
          end
          data << encode_sjis_csv(row)
        end
      end
    end

    def group_pipeline
      group = super
      group[:_id][:year] = { "$year" => "$created" }
      group[:_id][:month] = { "$month" => "$created" }
      group[:_id][:day] = { "$dayOfMonth" => "$created" }
      group
    end

    # [2018-01-01 00:00:00 +0900, 2018-01-02 00:00:00 +0900..]
    def ymd_header
      (@report.start_date.to_date..@report.end_date.to_date).to_a
    end
  end
end
