require 'spec_helper'

describe Cms::ExampleJob, dbscope: :example do
  let(:site) { create(:cms_site) }
  let(:group) { create(:cms_group) }
  let(:user) { create(:cms_user, uid: unique_id, name: unique_id, group_ids: [ group.id ]) }
  let(:node) { create(:cms_node, cur_site: site) }
  let(:page) { create(:cms_page, cur_site: site, cur_node: node) }
  let(:member) { create(:cms_member) }

  describe ".perform_later" do
    context "with no bindings and no parameters" do
      before do
        perform_enqueued_jobs { described_class.perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with site" do
      before do
        perform_enqueued_jobs { described_class.bind(site_id: site).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{site.domain}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with group" do
      before do
        perform_enqueued_jobs { described_class.bind(group_id: group).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{group.name}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with user" do
      before do
        perform_enqueued_jobs { described_class.bind(user_id: user).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{user.uid}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with node" do
      before do
        perform_enqueued_jobs { described_class.bind(node_id: node).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{node.filename}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with page" do
      before do
        perform_enqueued_jobs { described_class.bind(page_id: page).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{page.filename}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with member" do
      before do
        perform_enqueued_jobs { described_class.bind(member_id: member).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{member.email}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with parameters" do
      before do
        perform_enqueued_jobs { described_class.perform_later("world") }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, world!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end
  end

  describe ".perform_now" do
    context "with no bindings and no parameters" do
      before do
        described_class.perform_now
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with site" do
      before do
        described_class.bind(site_id: site).perform_now
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{site.domain}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with group" do
      before do
        described_class.bind(group_id: group).perform_now
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{group.name}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with user" do
      before do
        described_class.bind(user_id: user).perform_now
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{user.uid}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with node" do
      before do
        described_class.bind(node_id: node).perform_now
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{node.filename}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with page" do
      before do
        described_class.bind(page_id: page).perform_now
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{page.filename}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with member" do
      before do
        described_class.bind(member_id: member).perform_now
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, #{member.email}!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end

    context "with parameters" do
      before do
        described_class.perform_now("world")
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("Hello, world!")
        expect(log.log).to include("INFO -- : Completed Job")
      end
    end
  end
end
