class SS::Migration20191029000000
  include SS::Migration::Base

  depends_on "20181009202100"

  def change
    Opendata::Dataset.each do |item|
      item.resources.each do |resource|
        if resource.uuid.nil?
          resource.set(uuid: SecureRandom.uuid)
        end
        if resource.revision_id.nil?
          resource.set(revision_id: SecureRandom.uuid)
        end
      end
      item.url_resources.each do |resource|
        if resource.uuid.nil?
          resource.set(uuid: SecureRandom.uuid)
        end
        if resource.revision_id.nil?
          resource.set(revision_id: SecureRandom.uuid)
        end
      end
      item.set(uuid: SecureRandom.uuid) if item.uuid.nil?
    end
  end
end
