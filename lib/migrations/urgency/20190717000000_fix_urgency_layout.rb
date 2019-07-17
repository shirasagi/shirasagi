class SS::Migration20190717000000
  def change
    Urgency::Node::Layout.each do |node|
      next if node.state != "public"
      node.set(state: "closed")
    end
  end
end
