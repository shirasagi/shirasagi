puts "# files"

Dir.glob "files/**/*.*" do |file|
  puts name = file.sub(/^files\//, "")
  Fs.binwrite "#{@site.path}/#{name}", File.binread(file)
end

def save_ss_files(path, data)
  puts path
  cond = { site_id: @site._id, filename: data[:filename], model: data[:model] }

  file = Fs::UploadedFile.create_from_file(path)
  file.original_filename = data[:filename] if data[:filename].present?

  created = false
  item = SS::File.find_or_create_by(cond) do |item|
    item.in_file = file
    item.name = data[:name] if data[:name].present?
    created = true
  end

  if !created
    item.in_file = file
    item.name = data[:name] if data[:name].present?
    item.update
  end

  item
end
