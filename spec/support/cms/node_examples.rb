# Cms::Node
shared_examples "cms_node#spec" do
  let(:item_class) { item.class }

  describe "save" do
    it { expect(item.new_record?).to be_falsy }
  end
end

shared_examples "cms_node#spec_detail" do
  let(:item_class) { item.class }

  describe "scopes" do
    it { expect(item_class.filename('path')).not_to eq nil }
    it { expect(item_class.node(nil)).not_to eq nil }
    it { expect(item_class.and_public).not_to eq nil }
    it { expect(item_class.search({})).not_to eq nil }
  end

  describe "content_fields" do
    it { expect(item.state).not_to eq nil }
    it { expect(item.name).not_to eq nil }
    it { expect(item.filename).not_to eq nil }
    it { expect(item.depth).not_to eq nil }
    it { expect(item.order).not_to eq nil }
  end

  describe "node_fields" do
    it { expect(item.route).not_to eq nil }
    #it { expect(item.view_route).not_to eq nil }
    it { expect(item.shortcut).not_to eq nil }
  end

  describe "content_methods" do
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
    it { expect(item.parent).not_to eq nil }
    it { expect(item.serve_static_file?).not_to eq nil }
  end

  describe "node_methods" do
    it { expect(item.parents).not_to eq nil }
    it { expect(item.nodes).not_to eq nil }
    it { expect(item.children).not_to eq nil }
    it { expect(item.pages).not_to eq nil }
    it { expect(item.parts).not_to eq nil }
    it { expect(item.layouts).not_to eq nil }
  end
end
