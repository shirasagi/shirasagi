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

  let!(:node)   { create :article_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:item)   { create :article_page, cur_user: user_1, cur_site: cms_site, cur_node: node, layout_id: layout.id }

  describe "#perform" do
    before do
      # ready
      article_page = Article::Page.first
      now = Time.zone.now.advance(days: -1)
      Timecop.travel(10.days.ago) do
        article_page.release_date = now
        article_page.state = "public"
        article_page.save!
      end
      expect(article_page.state).to eq "ready"

      # perform_now
      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_now
      end
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(include("INFO -- : Started Job"))
      expect(log.logs).to include(include("INFO -- : Completed Job"))

      article_page = Article::Page.first
      expect(article_page.state).to eq "public"
    end
  end

  describe "#perform with branch page" do
    before do
      # Workflow::PagesController request_update
      article_page = Article::Page.first
      article_page.cur_site = site
      article_page.workflow_user_id = user_1.id
      article_page.workflow_state = "request"
      article_page.workflow_approvers = [
        { level: 1, user_id: user_2.id, state: "pending", comment: "" }
      ]
      article_page.workflow_required_counts = [ false ]
      article_page.save!

      # create branch
      copy = article_page.new_clone
      copy.cur_site = site
      copy.cur_node = node
      copy.master = article_page
      copy.save!

      # ready
      now = Time.zone.now.advance(days: -1)
      Timecop.travel(10.days.ago) do
        copy.release_date = now
        copy.state = "public"
        copy.save!
      end
      expect(copy.state).to eq "ready"

      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_now
      end
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(include("INFO -- : Started Job"))
      expect(log.logs).to include(include("INFO -- : Completed Job"))

      expect(Article::Page.count).to eq 1
      expect(Article::Page.first.state).to eq "public"
    end
  end
end
