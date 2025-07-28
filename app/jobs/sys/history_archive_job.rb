class Sys::HistoryArchiveJob < SS::ApplicationJob
  include Job::SS::TaskFilter
  include SS::HistoryArchiveBase

  self.task_name = 'sys:history_archive'

  private

  def sys_archiver
    @sys_archiver ||= SysArchiver.new
  end

  def cms_archiver(site_id)
    @cms_archiver ||= {}
    @cms_archiver[site_id] ||= CmsArchiver.new
  end

  def prepare_workdir
  end

  def select_histories_to_archive(now = Time.zone.now)
    save_term = SS.config.ss.history_log_saving_days.days
    History::Log.lt(created: threshold_day(now, save_term))
  end

  def threshold_day(now, save_term)
    now = now.beginning_of_day
    threshold = now - save_term
    threshold - threshold.wday.days
  end

  def select_histories
    @histories = select_histories_to_archive
  end

  def put_histories
    all_ids = @histories.order_by(created: 1).pluck(:id)
    all_ids.each_slice(100) do |ids|
      History::Log.in(id: ids).order_by(created: 1).to_a.each do |history|
        if history.site_id
          cms_archiver(history.site_id)
          @cms_archiver[history.site_id].append(history)
        else
          sys_archiver
          @sys_archiver.append(history)
        end
      end
    end
    @last_open_file_handle.close if @last_open_file_handle

    @last_open_file = nil
    @last_open_file_handle = nil
  end

  def register_archives
    @sys_archiver.register_archives if @sys_archiver
    if @cms_archiver
      @cms_archiver.each { |k, archiver| archiver.register_archives(k) }
    end
  end

  def create_archives
    @sys_archiver.create_archives if @sys_archiver

    if @cms_archiver
      @cms_archiver.each { |k, archiver| archiver.create_archives }
    end
  end

  def finalize_workdir
    @sys_archiver.finalize_workdir if @sys_archiver
    if @cms_archiver
      @cms_archiver.each { |k, archiver| archiver.finalize_workdir }
    end
  end

  class Archiver
    attr_accessor :file_model

    def initialize
      @work_dir = Rails.root.join('tmp', [ Process.pid, rand(1_000_000) ].join('.'))
      ::FileUtils.mkdir_p(@work_dir)
    end

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

    def append(history)
      file = to_archive_file(history)
      append_file(file, history)
    end

    def to_archive_file(history)
      @work_dir.join(
        "year-#{history.created.strftime('%Y')}",
        "week-#{self.week_of_year(history.created)}",
        "#{history.created.strftime('%Y%m%d')}.csv"
      )
    end

    def write_to_diff_file(file)
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

    def append_file(file, history)
      @csv_generator ||= Sys::HistoryCsv.new

      if @last_open_file != file
        write_to_diff_file(file)
      end

      @last_open_file_handle.write(@csv_generator.to_csv(history).encode('SJIS', invalid: :replace, undef: :replace))
    end

    def create_archives
      ::Dir[@work_dir.join('year-*')].each do |year_dir|
        ::Dir["#{year_dir}/week-*"].each do |week_dir|
          ::Zip::File.open("#{week_dir}.zip", ::Zip::File::CREATE) do |zip|
            ::Dir["#{week_dir}/*.csv"].each do |file|
              name = ::File.basename(file)
              name = ::Fs.zip_safe_name(name)
              zip.add(name, file)
            end
          end
        end
      end
    end

    def register_archives(site_id = nil)
      ::Dir[@work_dir.join('year-*')].each do |year_dir|
        ::Dir["#{year_dir}/week-*.zip"].each do |zip_file|
          num_year = year_dir.scan(/year-(\d+)/).first.first.to_i
          num_week = zip_file.scan(/week-(\d+)/).first.first.to_i

          filename = "#{num_year}-#{::File.basename(zip_file)}"

          start_at, end_at = self.range_of_week(num_year, num_week)
          name = "#{start_at.strftime('%Y年%1m月%1d日')}#{I18n.t("ss.dash")}#{end_at.strftime('%Y年%1m月%1d日')}.zip"

          create_empty_archive_file(name, filename, site_id) do |file|
            ::FileUtils.cp(zip_file, file.path)
          end
        end
      end
    end

    def create_empty_archive_file(name, filename, site_id, &block)
      if site_id
        Cms::HistoryArchiveFile.create_empty!(
          site_id: site_id, name: name, filename: filename, content_type: 'application/zip', &block
        )
      else
        Sys::HistoryArchiveFile.create_empty!(
          site_id: nil, name: name, filename: filename, content_type: 'application/zip', &block
        )
      end
    end

    def finalize_workdir
      return if @work_dir.blank?
      return if !::Dir.exist?(@work_dir)

      ::FileUtils.rm_rf(@work_dir)
    end
  end

  class SysArchiver < Archiver
    def initialize(*args)
      super
      @file_model = Sys::HistoryArchiveFile
    end
  end

  class CmsArchiver < Archiver
    def initialize(*args)
      super
      @file_model = Cms::HistoryArchiveFile
    end
  end
end
