json.array!(@items) do |item|
  json.extract! item, :filename, :path, :url, :full_url, :is_dir
end
