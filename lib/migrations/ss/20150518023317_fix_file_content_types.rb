class SS::Migration20150518023317
  def change
    SS::File.each do |file|
      ct = ::SS::MimeType.find(file.filename, file.content_type)
      if ct != file.content_type
        file.update! content_type: ct
      end
    end
  end
end
