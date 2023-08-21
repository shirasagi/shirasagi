class Gws::Chorg::MainRunner < Gws::Chorg::Runner
  include Chorg::Runner::Main
  include Job::SS::Binding::Task

  self.task_class = Gws::Chorg::Task

  private

  def init_context(opts = {})
    super
    create_staff_record
  end

  def create_staff_record
    return if @gws_staff_record.blank?
    # name and code are required
    return if @gws_staff_record['name'].blank? || @gws_staff_record['code'].blank?

    task.log("==電子職員録==")

    year = create_staff_record_year
    if year.errors.present?
      task.log("  次のエラーが発生しました。\n#{year.errors.full_messages.join("\n")}")
      return
    end

    job = Gws::StaffRecord::CopySituationJob.bind(site_id: site, user_id: user)
    job.perform_now(year.id.to_s)
    task.log("  #{year.name_with_code}: 電子職員録を作成しました。")
  end

  def create_staff_record_year
    close_date = Time.zone.now.end_of_month
    start_date = close_date - 1.year + 1.day
    start_date = start_date.beginning_of_month
    ret = Gws::StaffRecord::Year.new(
      cur_site: site, cur_user: user,
      name: @gws_staff_record['name'], code: @gws_staff_record['code'],
      start_date: start_date, close_date: close_date
    )

    ret.save
    ret
  end
end
