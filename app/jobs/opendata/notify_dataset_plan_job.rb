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
      elsif dataset.update_plan_unit == "yearly"
        if notify_yearly?(today, update_plan_date, 1)
          datasets << dataset
        end
      elsif dataset.update_plan_unit == "monthly"
        if notify_monthly?(today, update_plan_date, 1)
          datasets << dataset
        end
      elsif dataset.update_plan_unit == "quarterly"
        if notify_monthly?(today, update_plan_date, 3)
          datasets << dataset
        end
      elsif dataset.update_plan_unit == "two_yearly"
        if notify_yearly?(today, update_plan_date, 2)
          datasets << dataset
        end
      elsif dataset.update_plan_unit == "three_yearly"
        if notify_yearly?(today, update_plan_date, 3)
          datasets << dataset
        end
      elsif dataset.update_plan_unit == "four_yearly"
        if notify_yearly?(today, update_plan_date, 4)
          datasets << dataset
        end
      elsif dataset.update_plan_unit == "five_yearly"
        if notify_yearly?(today, update_plan_date, 5)
          datasets << dataset
        end
      end
    end

    if datasets.present?
      Opendata::Mailer.notify_dataset_update_plan(site, datasets).deliver_now
      #datasets.each { |dataset| dataset.set(update_plan_mail_state: "disabled") }
      put_log("send notify update_plan mail #{datasets.size}")
    end
  end

  def notify_yearly?(today, update_plan_date, cycle)
    return false if update_plan_date > today
    return false if update_plan_date.year >= today.year
    return false if ((today.year - update_plan_date.year) % cycle) != 0

    if update_plan_date.day == today.day
      return true
    else
      # 2/29
      if update_plan_date.month == 2 && update_plan_date.day == 29
        if !today.leap? && today.month == 2 && today.day == 28
          return true
        end
      end
    end

    return false
  end

  def required_months(start_month, cycle)
    (start_month...(start_month + 12)).map { |c| (c > 12) ? c - 12 : c }.select.with_index { |_, idx| (idx % cycle) == 0 }
  end

  def notify_monthly?(today, update_plan_date, cycle)
    return false if update_plan_date > today
    return false if required_months(update_plan_date.month, cycle).index(today.month).nil?

    update_plan_end_of_day = Time.days_in_month(update_plan_date.month, update_plan_date.year)
    today_end_of_day = Time.days_in_month(today.month, today.year)

    if update_plan_date.day == today.day
      return true
    elsif today.day == today_end_of_day #&& update_plan_end_of_day > today_end_of_day
      # ex)
      # update_plan 2019/1/31
      # today 2019/2/28
      if (today_end_of_day..update_plan_end_of_day).cover?(update_plan_date.day)
        return true
      end
    end

    return false
  end
end
