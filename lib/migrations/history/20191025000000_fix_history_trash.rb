class SS::Migration20191025000000
  include SS::Migration::Base

  depends_on "20190830000000"

  def change
    Rake.application.invoke_task("history:trash:clear")
  end
end
