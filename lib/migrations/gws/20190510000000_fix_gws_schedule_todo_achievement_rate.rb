class SS::Migration20190510000000
  def change
    Gws::Schedule::Todo.all.unscoped.where(todo_state: "finished").set(achievement_rate: 100)
  end
end
