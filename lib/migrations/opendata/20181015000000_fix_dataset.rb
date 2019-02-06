class SS::Migration20181015000000
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
