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

  item = SS::File.find_or_initialize_by(cond)
  return item if item.persisted?

  item.in_file = file
  if data[:name].present?
    name = data[:name]
    if !name.include?(".") && data[:filename].include?(".")
      name = "#{name}#{::File.extname(data[:filename])}"
    end
    item.name = name
  end
  item.cur_user = @user
  item.save

  item
end
