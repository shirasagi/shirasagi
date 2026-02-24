require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy node" do
    let!(:site) { cms_site }
    let!(:layout) { create :cms_layout, cur_site: site }
    let!(:node1) { create :inquiry_node_form, cur_site: site, layout: layout }
    let(:target_node_name) { unique_id }
    let(:target_node_filename) { unique_id }
    let!(:task) do
      create(
        :copy_nodes_task, site_id: site.id, node_id: node1.id,
        target_node_name: target_node_name, target_node_filename: target_node_filename
      )
    end

    before do
      node1.columns.create! attributes_for(:inquiry_column_name).reverse_merge(cur_site: site)
      node1.columns.create! attributes_for(:inquiry_column_email).reverse_merge(cur_site: site)
      node1.reload

      # 項目には廃止されたフィールド "permission_level" がある
      node1.columns.each do |column|
        column.collection.update_one({ _id: column.id }, { '$set' => { permission_level: 1 } })
      end
    end

    it do
      expect do
        job = Cms::Node::CopyNodesJob.bind(site_id: site.id, node_id: node1.id)
        job.perform_now(target_node_name: target_node_name, target_node_filename: target_node_filename)
      end.to output.to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).not_to include(include('コピーに失敗しました'))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      copied_node = Cms::Node.site(site).where(filename: target_node_filename).first
      expect(copied_node).to be_a(Inquiry::Node::Form)
      expect(copied_node.site_id).to eq site.id
      expect(copied_node.name).to eq target_node_name
      expect(copied_node.filename).to eq target_node_filename
      expect(copied_node.layout_id).to eq layout.id
      copied_node.columns.to_a.tap do |copied_columns|
        source_columns = node1.columns.to_a
        expect(copied_columns).to have(2).items
        expect(copied_columns[0].name).to eq source_columns[0].name
        expect(copied_columns[0].input_type).to eq source_columns[0].input_type
        expect(copied_columns[0].required).to eq source_columns[0].required
        expect(copied_columns[0].html).to eq source_columns[0].html
        expect(copied_columns[0].order).to eq source_columns[0].order
        expect(copied_columns[1].name).to eq source_columns[1].name
        expect(copied_columns[1].input_type).to eq source_columns[1].input_type
        expect(copied_columns[1].required).to eq source_columns[1].required
        expect(copied_columns[1].input_confirm).to eq source_columns[1].input_confirm
        expect(copied_columns[1].html).to eq source_columns[1].html
        expect(copied_columns[1].order).to eq source_columns[1].order
      end
    end
  end
end
