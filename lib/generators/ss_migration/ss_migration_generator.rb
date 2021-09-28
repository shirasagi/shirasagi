require 'rails/generators'

class SsMigrationGenerator < Rails::Generators::NamedBase
  class_option :module, type: :string, desc: "put migration file into specified module directory"

  source_root File.expand_path('templates', __dir__)

  SPEC_DIR = Rails.root.join("spec/lib/migrations")

  def create_migration_file
    @version = SS::Migration.new_version
    @latest_version = SS::Migration.latest_migration_file_version

    @migration_fullpath = SS::Migration::DIR
    @migration_fullpath = @migration_fullpath.join(options['module']) if options['module']
    @migration_fullpath = @migration_fullpath.join("#{@version}_#{file_name}.rb")
    @migration_relative_path = @migration_fullpath.to_s[(Rails.root.to_s.length + 1)..-1]
    template "migration.rb.tt", @migration_fullpath
  end

  def create_migration_spec
    @spec_fullpath = SPEC_DIR
    @spec_fullpath = @spec_fullpath.join(options['module']) if options['module']
    @spec_fullpath = @spec_fullpath.join("#{@version}_#{file_name}_spec.rb")
    @spec_relative_path = @spec_fullpath.to_s[(Rails.root.to_s.length + 1)..-1]
    template "migration_spec.rb.tt", @spec_fullpath
  end
end
