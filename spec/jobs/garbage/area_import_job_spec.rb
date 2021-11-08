require 'spec_helper'

describe Garbage::AreaImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group) { create :ss_group, name: 'group' }
  let!(:layout) { create :cms_layout, name: 'layout' }
  let!(:node) do
    create(
      :garbage_node_area_list,
      site: site,
      filename: "areas"
    )
  end

  let!(:file_path) { "#{::Rails.root}/spec/fixtures/garbage/garbage_areas.csv" }
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

        item1 = Garbage::Node::Area.site(site).find_by(filename: "areas/area1")
        expect(item1.name).to eq "area1"
        expect(item1.index_name).to eq "index_area1"
        expect(item1.layout_id).to eq layout.id
        expect(item1.groups.pluck(:name)).to match [group.name]

        item2 = Garbage::Node::Area.site(site).find_by(filename: "areas/area2")
        expect(item2.name).to eq "area2"
        expect(item2.index_name).to eq "index_area2"
        expect(item2.layout_id).to eq layout.id
        expect(item2.groups.pluck(:name)).to match [group.name]

        item3 = Garbage::Node::Area.site(site).find_by(filename: "areas/area3")
        expect(item3.name).to eq "area3"
        expect(item3.index_name).to eq "index_area3"
        expect(item3.layout_id).to eq layout.id
        expect(item3.groups.pluck(:name)).to match [group.name]
      end
    end
  end
end
