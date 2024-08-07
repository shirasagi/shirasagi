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
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with site" do
      before do
        perform_enqueued_jobs { described_class.bind(site_id: site.id).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{site.domain}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with group" do
      before do
        perform_enqueued_jobs { described_class.bind(group_id: group.id).perform_later }
      end

      it do
        expect(performed_jobs.size).to eq 1
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{group.name}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
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
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{user.uid}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
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
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{node.filename}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
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
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{page.filename}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
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
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{member.email}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
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
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, world!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end

  describe ".perform_now" do
    context "with no bindings and no parameters" do
      before do
        ss_perform_now described_class
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with site" do
      before do
        ss_perform_now described_class.bind(site_id: site.id)
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{site.domain}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with group" do
      before do
        ss_perform_now described_class.bind(group_id: group.id)
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{group.name}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with user" do
      before do
        ss_perform_now described_class.bind(user_id: user)
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{user.uid}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with node" do
      before do
        ss_perform_now described_class.bind(node_id: node)
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{node.filename}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with page" do
      before do
        ss_perform_now described_class.bind(page_id: page)
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{page.filename}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with member" do
      before do
        ss_perform_now described_class.bind(member_id: member)
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, #{member.email}!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    context "with parameters" do
      before do
        ss_perform_now(described_class, "world")
      end

      it do
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include("Hello, world!"))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end
end
