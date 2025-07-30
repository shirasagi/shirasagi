class Gws::Tabular::Form::DeleteService
  include ActiveModel::Model

  attr_accessor :site, :form

  def call
    form_release = find_release
    file_model = Gws::Tabular::File[form_release] if form_release

    return false unless form.destroy

    delete_class_file(form_release)
    delete_all_files(form_release, file_model)
    delete_all_releases(form_release, file_model)
    true
  end

  private

  def find_release
    releases = Gws::Tabular::FormRelease.where(form_id: form.id, revision: form.revision)
    releases.reorder(patch: -1).first
  end

  def delete_class_file(form_release)
    generator = Gws::Tabular::File::Generator.new(form_release: form_release)
    ::FileUtils.rm(generator.target_file_path)
  end

  def delete_all_releases(form_release, file_model)
    count = Gws::Tabular::FormRelease.unscoped.where(form_id: form.id).destroy_all
    Rails.logger.info { "#{Gws::Tabular::FormRelease.model_name.human}を#{count}件削除しました。" }
    count
  end

  def delete_all_files(form_release, file_model)
    # file は大量に存在する可能性があるので分割して削除する
    criteria = file_model.unscoped
    all_ids = criteria.pluck(:id)
    count = 0
    all_ids.each_slice(100) do |ids|
      count += criteria.in(id: ids).destroy_all
    end
    Rails.logger.info { "#{file_model.model_name.human}を#{count}件削除しました。" }
    count
  end
end
