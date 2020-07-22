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
  let!(:user_1) { create(:cms_test_user, group: cms_group, role: role) }
  let!(:user_2) { create(:cms_test_user, group: cms_group, role: role) }
  let!(:node)   { create :article_node_page, cur_site: site, layout_id: layout.id }

  let(:file) do
    tmp_ss_file site: site, cur_user: user_1, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", model: "article/page"
  end
  let!(:item) do
    create :article_page, cur_user: user_1, cur_site: site, cur_node: node, layout_id: layout.id, file_ids: [ file.id ],
           html: "<a href=\"#{file.url}\">#{file.humanized_name}</a>"
  end

  describe "#perform" do
    before do
      # ready
      now = Time.zone.now.advance(days: -1)
      Timecop.travel(10.days.ago) do
        item.release_date = now
        item.state = "public"
        item.save!
      end
      expect(item.state).to eq "ready"
      expect(item.files.count).to eq 1
      expect(item.files.first.id).to eq file.id

      # perform
      expect { described_class.bind(site_id: site).perform_now }.to output(include(item.full_url)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(include("INFO -- : Started Job"))
      expect(log.logs).to include(include("INFO -- : Completed Job"))

      item.reload
      expect(item.state).to eq "public"
    end
  end

  describe "#perform with branch page" do
    before do
      expect(History::Trash.all.count).to eq 0

      # Workflow::PagesController request_update
      item.workflow_user_id = user_1.id
      item.workflow_state = "request"
      item.workflow_approvers = [
        { level: 1, user_id: user_2.id, state: "pending", comment: "" }
      ]
      item.workflow_required_counts = [ false ]
      item.save!

      expect(item.state).to eq "public"
      expect(item.files.count).to eq 1
      expect(item.files.first.id).to eq file.id

      # create branch
      copy = item.new_clone
      copy.cur_site = site
      copy.cur_node = node
      copy.master = item
      copy.save!
      expect(copy.state).to eq "closed"
      expect(copy.files.count).to eq 1
      expect(copy.files.first.id).not_to eq file.id
      expect(copy.html).to include(file.humanized_name)
      expect(copy.html).not_to include(file.url)
      expect(copy.html).to include(copy.files.first.url)

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
      expect { described_class.bind(site_id: site).perform_now }.to output(include(copy.full_url)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(include("INFO -- : Started Job"))
      expect(log.logs).to include(include("INFO -- : Completed Job"))

      expect(Article::Page.count).to eq 1
      page = Article::Page.first
      expect(page.state).to eq "public"
      expect(page.file_ids.length).to eq 1
      expect(page.file_ids[0]).not_to eq file.id
      expect(page.html).to include(file.humanized_name)
      expect(page.html).not_to include(file.url)
      expect(page.html).to include(page.files.first.url)

      # there are no pages in trash
      expect(History::Trash.all.count).to eq 0
    end
  end
end
