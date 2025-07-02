class Gws::Tabular::FormPublishJob < Gws::ApplicationJob
  def perform(form_id)
    @item = Gws::Tabular::Form.site(site).find(form_id)

    Rails.logger.tagged(site.name, @item.name) do
      create_release
      create_migration
      execute_migration

      @item.update(state: "public") if @item.state != "public"
    rescue => e
      Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      raise
    end
  end

  private

  def create_release
    if @item.current_release
      Rails.logger.info { "already published" }
      @item.update(state: "public") if @item.state != "public"
      return
    end

    release = Gws::Tabular::FormRelease.new(cur_site: site, cur_space: @item.space, cur_form: @item, revision: @item.revision)
    release.save!

    backup_service = Gws::Column::BackupService.new(cur_site: site, cur_user: user, model: @item.class)
    backup_service.criteria = @item.class.unscoped.where(id: @item.id)
    backup_service.filename = release.archive_path
    backup_service.call

    @current_release = release
  end

  class MigrationCreator
    include ActiveModel::Model

    attr_accessor :site, :item, :current_release

    def call
      return false if current_columns.nil?

      ::File.dirname(current_release.migration_rb_path).tap do |dir_path|
        ::FileUtils.mkdir_p(dir_path)
      end
      ::File.open(current_release.migration_rb_path, "wt") do |f|
        f.puts "self.shirasagi = '#{SS.version}'"
        f.puts "self.site_id = '#{site.id}'"
        f.puts "self.form_id = '#{item.id}'"
        f.puts "self.release_id = '#{current_release.id}'"
        f.puts "self.revision_changes = [ #{prev_release.try(:revision) || "nil"}, #{current_release.revision} ]"
        f.puts

        current_columns.each do |current_column|
          current_column_id = current_column.id.to_s

          if added_column_ids.include?(current_column_id)
            f.puts "add_column '#{current_column.store_as_in_file}', type: '#{current_column.class.name}'"
            next
          end

          next unless common_column_ids.include?(current_column_id)

          prev_column = prev_columns.find { |prev_column| current_column_id == prev_column.id.to_s }

          prev_attrs = Base64.strict_encode64(prev_column.attributes.to_bson.to_s)
          current_attrs = Base64.strict_encode64(current_column.attributes.to_bson.to_s)
          f.puts "change_column '#{current_column.store_as_in_file}', changes: [ '#{prev_attrs}', '#{current_attrs}' ]"
        end

        f.puts
        prev_columns.each do |prev_column|
          prev_column_id = prev_column.id.to_s
          next unless deleted_column_ids.include?(prev_column_id)

          f.puts "delete_column '#{prev_column.store_as_in_file}', type: '#{prev_column.class.name}'"
        end
      end

      true
    end

    private

    def prev_release
      @prev_release ||= item.releases.where(revision: item.revision - 1).reorder(patch: -1).first
    end

    def prev_columns
      @prev_columns ||= begin
        if prev_release
          Gws::Tabular.released_columns(prev_release, site: site)
        else
          []
        end
      end
    end

    def current_columns
      @current_columns ||= Gws::Tabular.released_columns(@current_release, site: site)
    end

    def prev_column_ids
      @prev_column_ids ||= prev_columns.map { |column| column.id.to_s }
    end

    def current_column_ids
      @current_column_ids ||= current_columns.map { |column| column.id.to_s }
    end

    def added_column_ids
      @added_column_ids ||= Set.new(current_column_ids - prev_column_ids)
    end

    def deleted_column_ids
      @deleted_column_ids ||= Set.new(prev_column_ids - current_column_ids)
    end

    def common_column_ids
      @common_column_ids ||= Set.new(current_column_ids & prev_column_ids)
    end
  end

  def create_migration
    creator = MigrationCreator.new(site: site, item: @item, current_release: @current_release)
    creator.call
  end

  def execute_migration
    return unless @current_release

    path = @current_release.migration_rb_path
    return unless ::File.exist?(path)

    migration = Gws::Tabular::FormMigration.new
    migration.instance_eval(::File.read(path), ::File.basename(path))
    migration.call
  end
end
