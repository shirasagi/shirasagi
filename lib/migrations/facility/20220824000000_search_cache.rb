class SS::Migration20220824000000
  include SS::Migration::Base

  depends_on "20210825000000"

  def change
    ::Tasks::SS.invoke_task("facility:clear_search_cache")
  end
end
