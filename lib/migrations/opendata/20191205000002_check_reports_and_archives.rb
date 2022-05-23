class SS::Migration20191205000002
  include SS::Migration::Base

  depends_on "20181214000000"

  def change
    ::Tasks::Opendata.check_report_and_archives
  end
end
