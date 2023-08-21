module Gws::Workload::Graph::AggregationWorkCommentCsv
  extend ActiveSupport::Concern

  def aggregate_work_comment_enum_csv
    group_pipeline = {
      _id: { user_id: "$user_id", work_id: "$work_id", year: "$year", month: "$month", day: "$day" },
      day_worktime_minutes: { "$sum" => "$worktime_minutes" }
    }
    lookup_pipeline = {
      from: "gws_workload_works",
      localField: "_id.work_id",
      foreignField: "_id",
      as: "works"
    }
    project_pipeline = {
      year: "$_id.year",
      month: "$_id.month",
      day: "$_id.day",
      user_id: "$_id.user_id",
      work: { "$arrayElemAt" => [ "$works", 0 ] },
      day_worktime_minutes: "$day_worktime_minutes"
    }

    pipes = []
    pipes << { "$match" => comments.selector }
    pipes << { "$match" => { "year" => year } }
    pipes << { "$group" => group_pipeline }
    pipes << { "$lookup" => lookup_pipeline }
    pipes << { "$project" => project_pipeline }

    comment_by_days = Gws::Workload::WorkComment.collection.aggregate(pipes).to_a
    work_comment_csv(comment_by_days)
  end

  private

  def work_comment_csv_headers
    %w(
      year month day
      work_name coefficient worktime_minutes
      user_id
    ).map { |key| Gws::Workload::WorkComment.t(key) }
  end

  def work_comment_csv(comment_by_days)
    Enumerator.new do |y|
      y << encode_sjis(work_comment_csv_headers.to_csv)
      comment_by_days.each do |data|
        work = data["work"]
        work_name = work["name"] rescue nil

        row = []
        row << data["year"]
        row << data["month"]
        row << data["day"]
        row << work_name
        row << dig_load_coefficient(work, :load_id)
        row << dig_worktime_minutes(data, :day_worktime_minutes)
        row << dig_user_name(data, :user_id)
        y << encode_sjis(row.to_csv)
      end
    end
  end

  def dig_worktime_minutes(data, key)
    hours = data[key.to_s].to_i / 60
    minutes = data[key.to_s].to_i % 60
    format("%d:%02d", hours, minutes)
  rescue
    nil
  end

  def dig_user_name(data, key)
    @user_h ||= Gws::User.unscoped.to_a.index_by(&:id)
    @user_h[data[key.to_s]].name
  rescue
    nil
  end

  def dig_load_coefficient(data, key)
    @load_h ||= loads.index_by(&:id)
    @load_h[data[key.to_s]].coefficient
  rescue
    nil
  end
end
