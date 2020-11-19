require 'spec_helper'

describe Garbage::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group) { create :ss_group, name: 'group' }
  let!(:layout) { create :cms_layout, name: 'layout' }
  let!(:node) do
    create(
      :garbage_node_node,
      site: site,
      filename: "garbage",
      st_category_ids: [category1.id, category2.id, category3.id]
    )
  end

  let!(:categories) { create(:cms_node_node, site: site, filename: "garbage/categories") }
  let!(:category1) { create(:garbage_node_category, site: site, filename: "garbage/categories/c1", name: "c1") }
  let!(:category2) { create(:garbage_node_category, site: site, filename: "garbage/categories/c2", name: "c2") }
  let!(:category3) { create(:garbage_node_category, site: site, filename: "garbage/categories/c3", name: "c3") }

  let!(:file_path) { "#{::Rails.root}/spec/fixtures/garbage/garbage_pages.csv" }
  let!(:in_file) { Fs::UploadedFile.create_from_file(file_path) }
  let!(:ss_file) { create(:ss_file, site: site, in_file: in_file ) }

  describe ".perform_later" do
    context "with site" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node, user_id: cms_user).perform_later(ss_file.id)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        item1 = Garbage::Node::Page.find_by(filename: "garbage/item1")
        expect(item1.name).to eq "name1"
        expect(item1.layout_id).to eq layout.id
        expect(item1.categories.pluck(:name)).to match [category1.name]
        expect(item1.groups.pluck(:name)).to match [group.name]

        item2 = Garbage::Node::Page.find_by(filename: "garbage/item2")
        expect(item2.name).to eq "name2"
        expect(item2.layout_id).to eq layout.id
        expect(item2.categories.pluck(:name)).to match [category2.name]
        expect(item2.groups.pluck(:name)).to match [group.name]

        item3 = Garbage::Node::Page.find_by(filename: "garbage/item3")
        expect(item3.name).to eq "name3"
        expect(item3.layout_id).to eq layout.id
        expect(item3.categories.pluck(:name)).to match [category3.name]
        expect(item3.groups.pluck(:name)).to match [group.name]
        expect(item3.remark).to eq "one point"
      end
    end
  end
end
