class SS::Migration20190614000000
  def change
    Gws::Role.all.add_to_set(permissions: "use_gws_notice")
  end
end
