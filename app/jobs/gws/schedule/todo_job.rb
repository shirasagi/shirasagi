class Gws::Schedule::TodoJob < Gws::ApplicationJob

  def perform(opts = {})
    threshold = (6 + site.todo_delete_threshold * 6).month.ago

    count = Gws::Schedule::Todo.where(:created.lt => threshold).delete_all

    Rails.logger.info "#{threshold}以前のToDoを#{count}件削除しました。"
    puts_history(:info, "#{threshold}以前のToDoを#{count}件削除しました。")
  end
end
