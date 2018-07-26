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
      today = Time.zone.today

      if update_plan_date == today
        datasets << dataset
      elsif dataset.update_plan_unit == "yearly" && update_plan_date.month == today.month && update_plan_date.day == today.day
        datasets << dataset
      elsif dataset.update_plan_unit == "monthly" && update_plan_date.day == today.day
        datasets << dataset
      end
    end

    if datasets.present?
      Opendata::Mailer.notify_dataset_update_plan(site, datasets).deliver_now
      datasets.each { |dataset| dataset.set(update_plan_mail_state: "disabled") }
      put_log("send notify update_plan mail #{datasets.size}")
    end
  end
end
