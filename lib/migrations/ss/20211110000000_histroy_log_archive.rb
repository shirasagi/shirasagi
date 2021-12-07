class SS::Migration20211110000000
  include SS::Migration::Base

  depends_on "20211021000000"

  def change
    Sys::HistoryArchiveJob.perform_now
  end
end
