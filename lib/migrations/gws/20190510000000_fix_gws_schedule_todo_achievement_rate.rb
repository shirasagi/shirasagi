class SS::Migration20190510000000
  include SS::Migration::Base

  depends_on "20190412201700"

  def change
    Gws::Schedule::Todo.all.unscoped.where(todo_state: "finished").set(achievement_rate: 100)
  end
end
