require 'spec_helper'

describe SS::ExampleJob, dbscope: :example do
  let(:site) { create(:ss_site) }
  let(:group) { create(:ss_group) }
  let(:user) { create(:ss_user) }

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
        expect(log.log).to include("Hello, #{user.name}!")
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
        expect(log.log).to include("Hello, #{user.name}!")
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
