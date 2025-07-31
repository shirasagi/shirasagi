class Gws::Tabular::File::Generator
  include ActiveModel::Model

  attr_accessor :form_release
  attr_writer :site

  def site
    @site ||= form_release.site
  end

  def model_name
    @model_name ||= "File#{form.id}"
  end

  def target_file_path
    @target_file_path ||= "#{Gws::Tabular.file_class_dir}/#{model_name.underscore}.rb"
  end

  def call
    if ::File.exist?(target_file_path)
      file_time = ::File.mtime(target_file_path)
      file_time = file_time.in_time_zone
      # no need to create. this is up to date.
      return true if file_time >= form_release.updated.in_time_zone
    end

    synchronize do
      # ロックを獲得している間に他のスレッドでロードされたかもしれないので、もう一度確認
      if ::File.exist?(target_file_path)
        file_time = ::File.mtime(target_file_path)
        file_time = file_time.in_time_zone
        # no need to create. this is up to date.
        next true if file_time >= form_release.updated.in_time_zone
      end

      prepare

      puts "class Gws::Tabular::#{model_name}"
      indent 1 do
        puts "extend SS::Translation"
        puts "include SS::Document"
        puts "include Gws::Referenceable"
        puts "include Gws::Reference::User"
        puts "include Gws::Reference::Site"
        puts "include SS::Relation::File"
        puts "include Gws::Tabular::File"
        puts "include Gws::Reference::Tabular::Space"
        puts "include Gws::Reference::Tabular::Form"
        puts "include Gws::SitePermission"
        puts
        puts "identify_as 'Gws::Tabular::#{model_name}'"
        puts "store_in collection: 'gws_tabular_file_#{form.id}'"
        puts "set_permission_name 'gws_tabular_files'"
        puts
        puts "load_form_release '#{form.id}', #{form_release.revision}, #{form_release.patch}"
        if form.workflow_enabled?
          activate_workflow
        end
        puts
        puts "# 注意: include の順番によっては Workflow::Approver.search が有効化してしまうのでこの位置でオーバーライドする。"
        puts "include Gws::Tabular::File::Search"
        puts
        columns.each do |column|
          puts "add_column '#{column.id}' # #{column.name} (#{column.class.name})"
        end
      end
      puts "end"

      deploy_temp
    end

    true
  ensure
    finalize
  end

  private

  def form
    @form ||= Gws::Tabular.released_form(form_release, site: site) || form_release.form
  end

  def columns
    @columns ||= begin
      Gws::Tabular.released_columns(form_release, site: site) || form.columns.reorder(order: 1, id: 1).to_a
    end
  end

  def target_lock_file_path
    @target_lock_file_path ||= "#{Gws::Tabular.file_class_dir}/.#{model_name.underscore}.rb.lock"
  end

  def target_lock_file_stream
    @target_file_stream ||= begin
      ::FileUtils.mkdir_p(::File.dirname(target_lock_file_path))
      ::File.open(target_lock_file_path, "wt")
    end
  end

  def synchronize
    target_lock_file_stream.flock(File::LOCK_EX)
    target_lock_file_stream.puts("generate at #{Time.zone.now.iso8601} in #{Rails.application.hostname}@#{Process.pid}")
    yield
  end

  def prepare
    # ローカルストレージに一時ファイルを作成したいので "#{Rails.root}/tmp" に一時ファイルを作成する
    @temp_file = Tempfile.open("tabular_file_#{form.id}", "#{Rails.root}/tmp")
    @indent_level = 0
  end

  def finalize
    target_lock_file_stream.try(:close)
    @temp_file.try(:close)
  end

  def deploy_temp
    # "#{Rails.root}/private" は NFS でマウントされている可能性がある。
    # つまり "#{Rails.root}/private" へのコピーはネットワーク転送に他ならない。
    # 十分注意して "#{Rails.root}/private" へのコピーする
    @temp_file.flush

    Retriable.retriable do
      ::FileUtils.mkdir_p(Gws::Tabular.file_class_dir)

      ::FileUtils.cp(@temp_file.path, target_file_path)
      ::FileUtils.touch(target_file_path, mtime: form_release.updated.in_time_zone.to_time)
    end
  end

  def puts(str = nil)
    if str.blank?
      @temp_file.write("\n")
      return
    end

    @temp_file.write("  " * @indent_level)
    @temp_file.write(str)
    @temp_file.write("\n")
    nil
  end

  def indent(n)
    old_indent_level = @indent_level
    @indent_level += n
    begin
      yield
    ensure
      @indent_level = old_indent_level
    end
  end

  def activate_workflow
    puts
    puts "# workflow is enabled in this file"
    workflow_addons.each do |addon|
      puts "include #{addon.name}"
    end
    puts "cattr_reader(:approver_user_class) { Gws::User }"
  end

  def workflow_addons
    addons = []

    addons << Gws::Addon::Tabular::Inspection
    addons << Gws::Addon::Tabular::Circulation
    addons << Gws::Addon::Tabular::DestinationState
    addons << Gws::Addon::Tabular::Approver
    addons << Gws::Addon::Tabular::ApproverPrint
    addons << Gws::Workflow2::DestinationSetting
    addons << Gws::Tabular::Release

    addons
  end
end
