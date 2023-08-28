module Gws::Workload::Graph::AggregationCategory
  extend ActiveSupport::Concern

  def aggregate_client_datasets
    group_pipeline = { _id: "$client_id" }
    months.each do |m|
      group_pipeline["month#{m}_count"] = {
        "$sum" => { "$cond" => { if: { "$eq" => [ "$year_months.month", m ] }, then: 1, else: 0 } }
      }
    end

    pipes = []
    pipes << { "$match" => items.selector }
    pipes << { "$unwind" => "$year_months" }
    pipes << { "$match" => { "year_months.year" => year } }
    pipes << { "$group" => group_pipeline }

    count_by_client = Gws::Workload::Work.collection.aggregate(pipes).to_a
    count_by_client = count_by_client.index_by { |h| h["_id"] }

    set_client_datasets(count_by_client)
  end

  # 業務負荷：
  # (業務案件の終了日 - 業務案件の開始日) * 業務負荷係数
  # 業務にコメントがあった日付を1日分とする
  def aggregate_coefficient_datasets
    group_pipeline1 = { _id: { month: "$month", day: "$day", work_id: "$work_id" } }
    lookup_pipeline = {
      from: "gws_workload_works",
      localField: "_id.work_id",
      foreignField: "_id",
      as: "works"
    }
    project_pipeline = {
      month: "$_id.month",
      day: "$_id.day",
      work: { "$arrayElemAt" => [ "$works", 0 ] }
    }
    group_pipeline2 = { _id: "$work.load_id" }
    months.each do |m|
      group_pipeline2["month#{m}_count"] = {
        "$sum" => { "$cond" => { if: { "$eq" => [ "$month", m ] }, then: 1, else: 0 } }
      }
    end

    pipes = []
    pipes << { "$match" => comments.selector }
    pipes << { "$match" => { "year" => year } }
    pipes << { "$group" => group_pipeline1 }
    pipes << { "$lookup" => lookup_pipeline }
    pipes << { "$project" => project_pipeline }
    pipes << { "$group" => group_pipeline2 }

    count_by_load = Gws::Workload::WorkComment.collection.aggregate(pipes).to_a
    count_by_load = count_by_load.index_by { |h| h["_id"] }

    set_coefficient_datasets(count_by_load)
  end

  private

  def set_client_datasets(count_by_client)
    clients.each_with_index do |client, idx|
      data = count_by_client[client.id]
      data ||= {}

      count = months.map { |m| data["month#{m}_count"].to_i }
      client_datasets << {
        label: client.name,
        data: count,
        backgroundColor: Array.new(12, client.color),
        barPercentage: 0.5,
        order: (idx + 1)
      }
    end
  end

  def set_coefficient_datasets(count_by_load)
    loads.each_with_index do |load, idx|
      data = count_by_load[load.id]
      data ||= {}

      coefficients = months.map { |m| data["month#{m}_count"].to_i * load.coefficient }
      load_datasets << {
        label: load.name,
        data: coefficients,
        backgroundColor: Array.new(12, load.color),
        barPercentage: 0.3,
        order: (idx + 1)
      }
    end
  end
end
