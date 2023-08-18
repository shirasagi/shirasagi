class SS::Migration20221214000000
  include SS::Migration::Base

  depends_on "20220928000000"

  def change
    ::Tasks::SS.invoke_task("gws:aggregation:group:update")
  end
end
