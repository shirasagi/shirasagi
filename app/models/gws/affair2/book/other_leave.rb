class Gws::Affair2::Book::OtherLeave < Gws::Affair2::Book::Leave::Base
  include Gws::SitePermission

  set_permission_name "gws_affair2_other_leave_books"

  def load(site, user, year, group)
    @site = site
    @user = user
    @year = year
    @group = group

    @start_date = Time.zone.local(year, 1, 1)
    @close_date = @start_date.end_of_year

    @leave_files = Gws::Affair2::Leave::File.site(site).user(user).and([
      start_at: { "$gte" => start_date },
      close_at: { "$lte" => close_date },
      workflow_state: "approve"
    ]).order_by(start_at: 1).to_a
    @leave_files = @leave_files.select { |item| !item.paid_leave? }

    @tables = []
    @other_dates = {}
    leave_types.each do |k|
      @other_dates[k.to_s] = {}
    end

    if @leave_files.size == 0
      size = 7
    else
      size = (@leave_files.size / 7) * 7
      size += 7 if (@leave_files.size % 7) != 0
    end
    (size).times.each do |i|
      page = i / 7
      @tables[page] ||= []

      file = @leave_files[i]
      column = Gws::Affair2::Book::Leave::Column.new
      column.file = file

      if file && file.records.present?
        file.records.each do |record|
          @other_dates[record.leave_type][record.date] = true
        end
        column.other_dates = @other_dates.deep_dup
      end

      @tables[page] << column
    end
  end

  def title
    I18n.t("gws/affair2.book.leave.other_title", year: year)
  end

  def leave_types
    I18n.t("gws/affair2.book.leave.leave_type").keys.map(&:to_s)
  end
end
