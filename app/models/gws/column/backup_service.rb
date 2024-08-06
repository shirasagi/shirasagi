class Gws::Column::BackupService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :model, :criteria, :filename

  def call
    dirname = ::File.dirname(filename)
    FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)
    FileUtils.rm_f(filename) if ::File.exist?(filename)

    ::Zip::File.open(filename, ::Zip::File::CREATE) do |zip|
      zip.mkdir "db"

      backup_forms(zip)
      backup_columns(zip)
      write_tail(zip)
    end
  end

  private

  def backup_forms(zip)
    base_dir = "db/#{model.collection_name}"
    zip.mkdir base_dir
    criteria.each do |item|
      zip.get_output_stream("#{base_dir}/#{item.id}.bson") do |f|
        f.write item.attributes.to_bson.to_s
      end
    end
  end

  def backup_columns(zip)
    base_dir = "db/#{Gws::Column::Base.collection_name}"
    zip.mkdir base_dir
    all_form_ids = criteria.pluck(:id)
    all_columns = Gws::Column::Base.site(cur_site).where(form_type: model.name).in(form_id: all_form_ids)
    all_columns.each do |column|
      zip.get_output_stream("#{base_dir}/#{column.id}.bson") do |f|
        f.write column.attributes.to_bson.to_s
      end
    end
  end

  def write_tail(zip)
    zip.get_output_stream("tail.json") do |f|
      f.write({ version: SS.version, model: model.name, collection: model.collection_name }.to_json)
    end
  end
end
