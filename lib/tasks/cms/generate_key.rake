namespace :cms do
  task assign_generate_key: :environment do
    generate_key = SS.config.cms.generate_key
    exit if generate_key.blank?

    puts "# page"
    idx = 0
    Cms::Page.each do |item|
      next if !item.serve_static_file?

      key = generate_key[idx]
      item.set(generate_key: key)
      idx = ((idx + 1) == generate_key.size) ? 0 : (idx + 1)

      puts "#{key} #{item.filename}"
    end

    keys = Cms::Page.pluck(:generate_key)
    p generate_key.map { |key| [key, keys.count(key)] }.to_h

    puts "# node"
    idx = 0
    Cms::Node.each do |item|
      next if !item.serve_static_file?

      key = generate_key[idx]
      item.set(generate_key: key)
      idx = ((idx + 1) == generate_key.size) ? 0 : (idx + 1)

      puts "#{key} #{item.filename}"
    end

    keys = Cms::Node.pluck(:generate_key)
    p generate_key.map { |key| [key, keys.count(key)] }.to_h
  end
end
