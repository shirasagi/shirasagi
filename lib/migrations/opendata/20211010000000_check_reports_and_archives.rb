class SS::Migration20211010000000
  include SS::Migration::Base

  depends_on "20181214000000"

  def change
    ::Tasks::Opendata.check_report_and_archives
  end
end
