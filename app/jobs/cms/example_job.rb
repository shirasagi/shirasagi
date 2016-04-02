#
# 次のように呼び出す
#
#     Cms::ExampleJob.bind(site_id: @cur_site.id).perform_later('world')
#
# .id は省略できる
#
#     Cms::ExampleJob.bind(site_id: @cur_site).perform_later('world')
#
# サイトだけでなくユーザにも束縛できる
#
#     Cms::ExampleJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later('world')
#
# ActiveModel の where っぽく bind を重ね合せることもできる。
#
#     job = Cms::ExampleJob.bind(site_id: @cur_site)
#     job = job.bind(node_id: @cur_node) if @cur_node
#     job = job.bind(user_id: @cur_user) if @cur_user
#     job.perform_later('world')
#
# set を用いる場合は、最後にする。
#
#     Cms::ExampleJob.bind(site_id: @cur_site).set(queue: "severity_high").perform_later('world')
#     Cms::ExampleJob.bind(site_id: @cur_site).set(queue: "severity_high", wait: 30.seconds).perform_later('world')
#
class Cms::ExampleJob < Cms::ApplicationJob
  def perform(param)
    puts "hello #{param} @ #{site.domain}"
  end
end
