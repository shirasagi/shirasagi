module SS::HistoryArchiveBase
  extend ActiveSupport::Concern

  module ClassMethods
    def threshold_day(now, save_term)
      now = now.beginning_of_day
      threshold = now - save_term
      threshold - threshold.wday.days
    end

    def week_of_year(time)
      # when beginning of the year is sunday, we met some bugs in ruby.
      num = time.strftime('%U').to_i - time.beginning_of_year.strftime('%U').to_i
      format('%02d', num)
    end

    def last_sunday(time)
      time - time.wday.days
    end

    def range_of_week(year, week_of_year)
      start_at = last_sunday(Time.zone.parse("#{year}/01/01") + week_of_year.weeks)
      end_at = start_at + 6.days

      start_at += 1.day while start_at.year < year
      end_at -= 1.day while end_at.year > year

      [start_at, end_at.end_of_day]
    end
  end

  def perform(*args)
    @options = args.extract_options!

    prepare_workdir

    select_histories

    put_histories

    create_archives

    register_archives

    destroy_histories
  ensure
    finalize_workdir
  end

  private

  def prepare_workdir
    @work_dir = Rails.root.join('tmp', [ Process.pid, rand(1_000_000) ].join('.'))
    ::FileUtils.mkdir_p(@work_dir)
  end

  def finalize_workdir
    return if @work_dir.blank?
    return if !::Dir.exist?(@work_dir)

    ::FileUtils.rm_rf(@work_dir)
  end

  def to_archive_file(history)
    @work_dir.join(
      "year-#{history.created.strftime('%Y')}",
      "week-#{self.class.week_of_year(history.created)}",
      "#{history.created.strftime('%Y%m%d')}.csv"
    )
  end

  def append_file(file, history)
    if @last_open_file != file
      @last_open_file_handle.close if @last_open_file_handle

      dirname = ::File.dirname(file)
      ::FileUtils.mkdir_p(dirname) if !::Dir.exist?(dirname)

      @last_open_file = file
      @last_open_file_handle = ::File.open(file, 'a')
      @last_open_file_handle.binmode
      @last_open_file_handle.sync = true

      if ::File.size(file) == 0
        @last_open_file_handle.write(@csv_generator.csv_headers.to_csv.encode('SJIS', invalid: :replace, undef: :replace))
      end
    end

    @last_open_file_handle.write(@csv_generator.to_csv(history).encode('SJIS', invalid: :replace, undef: :replace))
  end

  def create_archives
    ::Dir[@work_dir.join('year-*')].each do |year_dir|
      ::Dir["#{year_dir}/week-*"].each do |week_dir|
        ::Zip::File.open("#{week_dir}.zip", ::Zip::File::CREATE) do |zip|
          ::Dir["#{week_dir}/*.csv"].each do |file|
            name = ::File.basename(file)
            zip.add(name, file)
          end
        end
      end
    end
  end

  def register_archives
    ::Dir[@work_dir.join('year-*')].each do |year_dir|
      ::Dir["#{year_dir}/week-*.zip"].each do |zip_file|
        num_year = year_dir.scan(/year-(\d+)/).first.first.to_i
        num_week = zip_file.scan(/week-(\d+)/).first.first.to_i

        filename = "#{num_year}-#{::File.basename(zip_file)}"

        start_at, end_at = self.class.range_of_week(num_year, num_week)
        name = "#{start_at.strftime('%Y年%1m月%1d日')}〜#{end_at.strftime('%Y年%1m月%1d日')}.zip"

        create_empty_archive_file(name, filename) do |file|
          ::FileUtils.cp(zip_file, file.path)
        end
      end
    end
  end

  def destroy_histories
    @histories.destroy_all if @histories
  end
end
