# Cms::Node
shared_examples "cms_node#spec" do
  let(:item_class) { item.class }

  describe "scopes" do
    it { expect(item_class.filename('path')).not_to eq nil }
    it { expect(item_class.node(nil)).not_to eq nil }
    it { expect(item_class.and_public).not_to eq nil }
    it { expect(item_class.search({})).not_to eq nil }
  end

  describe "fields" do
    it { expect(item.state).not_to eq nil }
    it { expect(item.name).not_to eq nil }
    it { expect(item.filename).not_to eq nil }
    it { expect(item.depth).not_to eq nil }
    it { expect(item.order).not_to eq nil }
  end

  describe "methods" do
    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.json_path).not_to eq nil }
    it { expect(item.json_url).not_to eq nil }
    it { expect(item.public?).not_to eq nil }
    it { expect(item.public_node?).not_to eq nil }
    it { expect(item.status).not_to eq nil }
    it { expect(item.state_options).not_to eq nil }
    it { expect(item.state_private_options).not_to eq nil }
    it { expect(item.parents).not_to eq nil }
    it { expect(item.nodes).not_to eq nil }
    it { expect(item.children).not_to eq nil }
    it { expect(item.pages).not_to eq nil }
    it { expect(item.parts).not_to eq nil }
    it { expect(item.layouts).not_to eq nil }
    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.serve_static_file?).not_to eq nil }
    it { expect(item.serve_static_relation_files?).not_to eq nil }
  end
end
