class Gws::Tabular::File::PublishUploadFileJob < Gws::ApplicationJob
  def perform(space_id, form_id, release_id, publish_field_names, depublish_field_names)
    @cur_release = ::Gws::Tabular::FormRelease.find(release_id)
    @cur_file_model = ::Gws::Tabular::File[@cur_release]

    each_file do |file|
      if ::Gws::Tabular.public_file?(file)
        publish_all_upload_files(file, publish_field_names)
      else
        depublish_all_upload_files(file, publish_field_names)
      end

      depublish_all_upload_files(file, depublish_field_names)
    end
  end

  private

  def each_file(&block)
    criteria = @cur_file_model.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end

  def publish_all_upload_files(file, publish_field_names)
    return if publish_field_names.blank?

    publish_field_names.each do |field_name|
      upload_file_id = file.read_tabular_value(field_name)
      next unless upload_file_id

      ::SS::File.each_file([ upload_file_id ]) do |upload_file|
        if upload_file.owner_item_id == file.id
          ::Gws.publish_file(site, upload_file)
        end
      end
    end
  end

  def depublish_all_upload_files(file, publish_field_names)
    return if publish_field_names.blank?

    publish_field_names.each do |field_name|
      upload_file_id = file.read_tabular_value(field_name)
      next unless upload_file_id

      ::SS::File.each_file([ upload_file_id ]) do |upload_file|
        if upload_file.owner_item_id == file.id
          ::Gws.depublish_file(site, upload_file)
        end
      end
    end
  end
end
