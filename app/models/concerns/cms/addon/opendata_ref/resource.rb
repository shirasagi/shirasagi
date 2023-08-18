module Cms::Addon::OpendataRef::Resource
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :opendata_resources, type: Hash, metadata: { on_copy: :clear, branch: false }

    permit_params opendata_resources: {}

    validate :validate_opendata_resources
    around_clone_files :clone_opendata_resources
  end

  def opendata_resource_state_options
    %w(none same).map do |v|
      [ I18n.t("cms.options.opendata_resource.#{v}"), v ]
    end
  end

  def init_opendata_resources(file)
    file_id = file.id.to_s
    self.opendata_resources ||= {}
    self.opendata_resources[file_id] ||= {}
    self.opendata_resources[file_id][:state] ||= 'none'
  end

  def update_opendata_resources!(file_id, key_values)
    hash = self.opendata_resources
    hash = hash.present? ? hash.dup : {}

    file_id = file_id.to_s
    hash[file_id] ||= {}
    key_values.each do |key, value|
      key = key.to_s
      if key == 'file_id'
        next
      elsif key == 'dataset_id'
        if value.present?
          hash[file_id]['dataset_ids'] = [ Integer(value) ]
        else
          hash[file_id]['dataset_ids'] = []
        end
      elsif key == 'license_id'
        if value.present?
          hash[file_id]['license_ids'] = [ Integer(value) ]
        else
          hash[file_id]['license_ids'] = []
        end
      else
        hash[file_id][key] = value
      end
    end
    self.opendata_resources = hash

    return false if self.invalid?

    update!(opendata_resources: hash) if hash.present?
  end

  def opendata_resources_state(file)
    hash = self.opendata_resources
    return 'none' if hash.blank?

    file_id = file.id.to_s
    return hash.dig(file_id, 'state').presence || 'none'
  end

  def opendata_resources_dataset_ids(file)
    hash = self.opendata_resources
    return [] if hash.blank?

    file_id = file.id.to_s
    return hash.dig(file_id, 'dataset_ids') || []
  end

  def opendata_resources_datasets(file)
    Opendata::Dataset.in(id: opendata_resources_dataset_ids(file))
  end

  def opendata_resources_license_ids(file)
    hash = self.opendata_resources
    return [] if hash.blank?

    file_id = file.id.to_s
    return hash.dig(file_id, 'license_ids') || []
  end

  def opendata_resources_licenses(file)
    Opendata::License.in(id: opendata_resources_license_ids(file))
  end

  def opendata_resources_text(file)
    hash = self.opendata_resources
    return if hash.blank?

    file_id = file.id.to_s
    return hash.dig(file_id, 'text').presence || nil
  end

  private

  def validate_opendata_resources
    return if opendata_dataset_state.blank? || opendata_dataset_state == 'none'

    hash = self.opendata_resources
    hash = hash.present? ? hash.dup : {}
    hash.each do |k, v|
      next if v['state'].blank? || v['state'] == 'none' || v['license_ids'].present?

      errors.add(:base, "#{I18n.t('cms.opendata_ref/resource.license_id')}#{I18n.t("errors.messages.not_select")}")
    end
  end

  def clone_opendata_resources
    ids = yield

    hash = self.opendata_resources
    return if hash.blank?

    hash = hash.dup
    hash.keys.map(&:to_i).each do |k|
      next if ids[k].blank?
      hash[ids[k].to_s] = hash.delete(k.to_s)
    end

    self.opendata_resources = hash
  end
end
