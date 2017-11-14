class Gws::Circular::DeleteJob < Gws::ApplicationJob

  def perform(opts = {})
    threshold = (6 + site.todo_delete_threshold * 6).month.ago

    count = Gws::Circular::Post.where(:created.lt => threshold).destroy_all

    Rails.logger.info "#{threshold}以前の回覧を#{count}件削除しました。"
  end
end
