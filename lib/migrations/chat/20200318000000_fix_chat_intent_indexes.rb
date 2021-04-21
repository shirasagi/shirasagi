class SS::Migration20200318000000
  include SS::Migration::Base

  # depends_on "20200304000001"

  def change
    Chat::Intent.remove_indexes
    Chat::Intent.create_indexes
  end
end
