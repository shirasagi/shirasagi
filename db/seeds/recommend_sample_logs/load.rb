puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?
puts "Please input clients: clients=[number of clients]" or exit if ENV['clients'].blank?
puts "Please input logs: logs=[number of 1 person's logs]" or exit if ENV['logs'].blank?

@site = SS::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site

@clients = ENV['clients'].to_i
@logs = ENV['logs'].to_i

def save_log(token, item)
  log = Recommend::History::Log.new(
    token: token,
    site: @site,
    path: item.url,
    access_url: item.full_url,
    target_class: item.class.to_s,
    target_id: item.id,
    remote_addr: "192.0.2.0",
    user_agent: "dummy connection (input by seed recommend_sample_logs)"
  )
  log.save!
  log
end

def find_random_content
  if rand(2) == 1
    find_random_page
  else
    find_random_node
  end
end

def find_random_page
  criteria = Cms::Page.site(@site).where(
    :route.in => ["cms/page", "article/page", "faq/page", "event/page"]
  )
  count = criteria.count
  Cms::Page.find(-1) unless count > 0

  # ref: http://stackoverflow.com/questions/7759250/mongoid-random-document
  (0..(count - 1)).sort_by { rand }.slice(0, 1).collect! do |i|
    criteria.skip(i).first
  end.first
end

def find_random_node
  criteria = Cms::Node.site(@site).where(
    :route.in =>
    [
     "cms/page", "cms/node", "article/page",
     "category/page", "category/node",
     "faq/page", "event/page", "inquiry/form"
    ]
  )
  count = criteria.count
  Cms::Page.find(-1) unless count > 0

  # ref: http://stackoverflow.com/questions/7759250/mongoid-random-document
  (0..(count - 1)).sort_by { rand }.slice(0, 1).collect! do |i|
    criteria.skip(i).first
  end.first
end

puts "# history logs"

@clients.times do
  token = nil
  @logs.times do
    item = find_random_content
    log = save_log(token, item)
    token = log.token
    puts "#{log.token} #{log.path}"
  end
end
