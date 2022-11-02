module Gws::Workload::Graph::AggregationTotal
  extend ActiveSupport::Concern

  def aggregate_total_datasets
    group_pipeline = { _id: "$load_id" }
    months.each do |m|
      group_pipeline["month#{m}_count"] = {
        "$sum" => { "$cond" => { if: { "$eq" => [ "$year_months.month", m ] }, then: 1, else: 0 } }
      }
    end

    pipes = []
    pipes << { "$match" => @items.selector }
    pipes << { "$unwind" => "$year_months" }
    pipes << { "$match" => { "year_months.year" => year } }
    pipes << { "$group" => group_pipeline }

    aggregation1 = Gws::Workload::Work.collection.aggregate(pipes)
    aggregation1 = aggregation1.to_a.index_by { |h| h["_id"] }

    aggregation2 = {}
    aggregation1.each_value do |data|
      months.each do |month|
        aggregation2["month#{month}_count"] ||= 0
        aggregation2["month#{month}_count"] += data["month#{month}_count"]
      end
    end

    loads.each_with_index do |load, idx|
      data = aggregation1[load.id] || {}

      percentages = months.map do |month|
        load_count = data["month#{month}_count"] || 0
        total_count = aggregation2["month#{month}_count"] || 0
        percentage = (total_count == 0) ? 0 : (load_count.to_f / total_count) * 100
        percentage
      end

      total_datasets << {
        label: load.name,
        data: percentages,
        backgroundColor: Array.new(12, load.bar_color),
        barPercentage: 0.5,
        datalabels: { display: false },
        order: (2 + idx),
        yAxisID: 'y'
      }
    end

    yellow = "hsl(40,100%,50%)"
    total_count = months.map { |month| aggregation2["month#{month}_count"] }
    total_datasets << {
      label: I18n.t("gws/workload.graph.total.label"),
      data: total_count,
      backgroundColor: yellow,
      borderColor: yellow,
      type: 'line',
      fill: false,
      order: 1,
      yAxisID: 'y2'
    }
  end

  def aggregate_worktime_datasets
    group_pipeline = { _id: "$user_id" }
    months.each do |m|
      group_pipeline["worktime_month#{m}_minutes"] = {
        "$sum" => { "$cond" => { if: { "$eq" => [ "$month", m ] }, then: "$worktime_minutes", else: 0 } }
      }
    end

    pipes = []
    pipes << { "$match" => comments.selector }
    pipes << { "$match" => { "year" => year } }
    pipes << { "$group" => group_pipeline }
    aggregation = Gws::Workload::WorkComment.collection.aggregate(pipes).to_a
    aggregation = aggregation.index_by { |h| h["_id"] }

    graph_users.each do |graph_user|
      user = graph_user.user
      data = aggregation[user.id]
      data ||= {}

      hours = months.map { |m| (data["worktime_month#{m}_minutes"].to_f / 60).round(2) }
      worktime_datasets << {
        label: user.name,
        data: hours,
        backgroundColor: Array.new(12, graph_user.color),
        barPercentage: 0.5
      }
    end
  end

  def aggregate_overtime_datasets
    overtime_h = overtimes.to_a.index_by(&:user_id)

    graph_users.each do |graph_user|
      user = graph_user.user
      data = overtime_h[user.id]

      hours = months.map { |m| (data.send("month#{m}_minutes").to_f / 60).round(2) }
      overtime_datasets << {
        label: user.name,
        data: hours,
        backgroundColor: Array.new(12, graph_user.color),
        barPercentage: 0.5
      }
    end
  end
end
