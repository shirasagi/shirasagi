require 'spec_helper'

describe Cms::Page::ReleaseJob, dbscope: :example do
  let!(:site)   { cms_site }
  let!(:layout) { create_cms_layout }

  let!(:group) { cms_group }
  let!(:role) do
    Cms::Role.create!(
      name: "role_#{unique_id}",
      permissions: Cms::Role.permission_names,
      site_id: site.id
    )
  end
  let!(:user1) { create(:cms_test_user, group: cms_group, role: role) }
  let!(:user2) { create(:cms_test_user, group: cms_group, role: role) }
  let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }

  let(:file) do
    tmp_ss_file site: site, cur_user: user1, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", model: "article/page"
  end
  let(:map_point1) do
    {
      "name" => unique_id, "loc" => [ rand(130..140), rand(30..40) ], "text" => "",
      "image" => "/assets/img/googlemaps/marker#{rand(0..9)}.png"
    }
  end
  let!(:item1) do
    create :article_page, cur_user: user1, cur_site: site, cur_node: node, layout_id: layout.id, file_ids: [ file.id ],
           html: "<a href=\"#{file.url}\">#{file.humanized_name}</a>", map_points: [ map_point1 ]
  end
  let!(:item2) do
    create :article_page, cur_user: user1, cur_site: site, cur_node: node, layout_id: layout.id,
           html: "<a href=\"#{item1.url}\">#{item1.name}</a>"
  end
  let!(:item3) do
    create :article_page, cur_user: user1, cur_site: site, cur_node: node, layout_id: layout.id,
           html: "<a href=\"#{item2.url}\">#{item2.name}</a>"
  end

  describe "#perform" do
    before do
      # ready
      now = Time.zone.now.advance(days: -1)
      Timecop.travel(10.days.ago) do
        item1.release_date = now
        item2.close_date = now
        item3.release_date = now - 1.day
        item3.close_date = now
        item1.state = "public"
        item2.state = "public"
        item3.state = "public"
        item1.save!
        item2.save!
        item3.save!
      end
      expect(item1.state).to eq "ready"
      expect(item2.state).to eq "public"
      expect(item3.state).to eq "ready"
      expect(item1.files.count).to eq 1
      expect(item1.files.first.id).to eq file.id

      # perform
      expect { described_class.bind(site_id: site.id).perform_now }.to output(include(item1.full_url)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      item1.reload
      item2.reload
      item3.reload
      expect(item1.state).to eq "public"
      expect(item2.state).to eq "closed"
      expect(item3.state).to eq "closed"
    end
  end

  describe "#perform with branch page" do
    before do
      expect(History::Trash.all.count).to eq 0

      # Workflow::PagesController request_update
      item1.workflow_user_id = user1.id
      item1.workflow_state = "request"
      item1.workflow_approvers = [
        { level: 1, user_id: user2.id, state: "pending", comment: "" }
      ]
      item1.workflow_required_counts = [ false ]
      item1.save!

      expect(item1.state).to eq "public"
      expect(item1.files.count).to eq 1
      expect(item1.files.first.id).to eq file.id

      # create branch
      copy = item1.new_clone
      copy.cur_site = site
      copy.cur_node = node
      copy.master = item1
      copy.save!
      expect(copy.state).to eq "closed"
      expect(copy.files.count).to eq 1
      expect(copy.files.first.id).to eq file.id
      expect(copy.html).to include(file.humanized_name)
      expect(copy.html).to include(file.url)
      expect(copy.html).to eq item1.html

      # ready
      now = Time.zone.now.advance(days: -1)
      Timecop.travel(10.days.ago) do
        # clean up member variables by loading from database
        copy = Article::Page.find(copy.id)
        copy.cur_site = site
        copy.cur_node = node
        copy.release_date = now
        copy.state = "public"
        copy.save!
      end
      expect(copy.state).to eq "ready"
      expect(copy.files.count).to eq 1
      expect(copy.html).to include(copy.files.first.url)

      # perform
      expect { described_class.bind(site_id: site.id).perform_now }.to output(include(copy.full_url)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(Article::Page.count).to eq 3
      page = Article::Page.first
      expect(page.state).to eq "public"
      expect(page.file_ids.length).to eq 1
      expect(page.file_ids[0]).to eq file.id
      expect(page.html).to include(file.humanized_name)
      expect(page.html).to include(file.url)

      # there are no pages in trash
      expect(History::Trash.all.count).to eq 0

      expect(Map::Geolocation.all.count).to eq 1
    end
  end
end
