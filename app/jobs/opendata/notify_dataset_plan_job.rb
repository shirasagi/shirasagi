class Opendata::NotifyDatasetPlanJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.warn(message)
    puts message
  end

  def perform
    datasets = []

    dataset_ids = Opendata::Dataset.site(site).where(
      :update_plan_date.exists => true,
      :update_plan_mail_state => "enabled"
    ).pluck(:id)
    dataset_ids.each do |id|
      dataset = Opendata::Dataset.find(id) rescue nil
      next unless dataset

      update_plan_date = dataset.update_plan_date.to_date
      next if update_plan_date.blank?

      today = Time.zone.today
      next if update_plan_date > today

      if update_plan_date == today
        datasets << dataset
      elsif dataset.update_plan_unit == "yearly" && update_plan_date.month == today.month && update_plan_date.day == today.day
        datasets << dataset
      elsif dataset.update_plan_unit == "monthly"

        update_plan_end_of_day = Time.days_in_month(update_plan_date.month, update_plan_date.year)
        today_end_of_day = Time.days_in_month(today.month, today.year)

        if update_plan_date.day == today.day
          datasets << dataset
        elsif today.day == today_end_of_day #&& update_plan_end_of_day > today_end_of_day

          if (today_end_of_day..update_plan_end_of_day).include?(update_plan_date.day)
            # ex)
            # update_plan 2019/1/31
            # today 2019/2/28
            datasets << dataset
          end

        end
      end
    end

    if datasets.present?
      Opendata::Mailer.notify_dataset_update_plan(site, datasets).deliver_now
      datasets.each { |dataset| dataset.set(update_plan_mail_state: "disabled") }
      put_log("send notify update_plan mail #{datasets.size}")
    end
  end
end
