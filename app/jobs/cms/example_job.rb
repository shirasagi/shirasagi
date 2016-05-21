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
# set を用いて job / queue の設定を追加することもできる。
#
#     Cms::ExampleJob.bind(site_id: @cur_site).set(queue: "severity_high").perform_later('world')
#     Cms::ExampleJob.bind(site_id: @cur_site).set(queue: "severity_high", wait: 30.seconds).perform_later('world')
#
# bind と set の順番は関係ない。set を先にしてもいける。
#
#     Cms::ExampleJob.set(queue: "severity_high").bind(site_id: @cur_site).perform_later('world')
#     Cms::ExampleJob.set(queue: "severity_high", wait: 30.seconds).bind(site_id: @cur_site).perform_later('world')
#
class Cms::ExampleJob < Cms::ApplicationJob
  def perform(param = "")
    Rails.logger.info "Hello, #{site.domain}!" if site.present?
    Rails.logger.info "Hello, #{group.name}!" if group.present?
    Rails.logger.info "Hello, #{user.uid}!" if user.present?
    Rails.logger.info "Hello, #{node.filename}!" if node.present?
    Rails.logger.info "Hello, #{page.filename}!" if page.present?
    Rails.logger.info "Hello, #{member.email}!" if member.present?
    Rails.logger.info "Hello, #{param}!" if param.present?
  end
end
