class SS::Migration20190717000000
  include SS::Migration::Base

  depends_on "20190705000000"

  def change
    Urgency::Node::Layout.each do |node|
      next if node.state == "closed"
      node.set(state: "closed")
    end
  end
end
