require 'spec_helper'

describe Ezine::DeliverReservedJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :ezine_node_page, cur_site: site }
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:deliver_date1) { now + 3.days }
  let(:deliver_date2) { now + 7.days }
  let!(:page1) do
    create(:ezine_page, cur_site: site, cur_node: node, html: "<p>#{unique_id}</p>", text: unique_id, deliver_date: deliver_date1)
  end
  let!(:page2) do
    create(:ezine_page, cur_site: site, cur_node: node, html: "<p>#{unique_id}</p>", text: unique_id, deliver_date: deliver_date2)
  end
  let!(:member1) { create :ezine_member, node: node, email: unique_email, email_type: "text" }
  let!(:member2) { create :ezine_member, node: node, email: unique_email, email_type: "html" }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  it do
    Timecop.freeze(now) do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.not_to output.to_stdout
    end

    expect(Job::Log.count).to eq 1
    Job::Log.all.order_by(id: -1).first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.state).to eq "completed"
    end
    expect(ActionMailer::Base.deliveries.length).to eq 0

    Timecop.freeze(deliver_date1 - 1.second) do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.not_to output.to_stdout
    end

    expect(Job::Log.count).to eq 2
    Job::Log.all.order_by(id: -1).first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.state).to eq "completed"
    end
    expect(ActionMailer::Base.deliveries.length).to eq 0

    Timecop.freeze(deliver_date1) do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to \
        output(include("To: #{member1.email}", "To: #{member2.email}")).to_stdout
    end

    expect(Job::Log.count).to eq 3
    Job::Log.all.order_by(id: -1).first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).to include(/INFO -- : .* delivering to 2 members/)
      expect(log.logs).to include(/INFO -- : .* To: #{member1.email}/)
      expect(log.logs).to include(/INFO -- : .* To: #{member2.email}/)
      expect(log.state).to eq "completed"
    end
    expect(ActionMailer::Base.deliveries.length).to eq 2
    ActionMailer::Base.deliveries[0].tap do |mail|
      expect(mail.subject).to eq page1.name
      expect(mail.from).to have(1).items
      expect(mail.from).to include(node.sender_email)
      expect(mail.to).to have(1).items
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end
    ActionMailer::Base.deliveries[1].tap do |mail|
      expect(mail.subject).to eq page1.name
      expect(mail.from).to have(1).items
      expect(mail.from).to include(node.sender_email)
      expect(mail.to).to have(1).items
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    Timecop.freeze(deliver_date2) do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to \
        output(include("To: #{member1.email}", "To: #{member2.email}")).to_stdout
    end

    expect(Job::Log.count).to eq 4
    Job::Log.all.order_by(id: -1).first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).to include(/INFO -- : .* delivering to 2 members/)
      expect(log.logs).to include(/INFO -- : .* To: #{member1.email}/)
      expect(log.logs).to include(/INFO -- : .* To: #{member2.email}/)
      expect(log.state).to eq "completed"
    end
    expect(ActionMailer::Base.deliveries.length).to eq 4
    ActionMailer::Base.deliveries[2].tap do |mail|
      expect(mail.subject).to eq page2.name
      expect(mail.from).to have(1).items
      expect(mail.from).to include(node.sender_email)
      expect(mail.to).to have(1).items
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end
    ActionMailer::Base.deliveries[3].tap do |mail|
      expect(mail.subject).to eq page2.name
      expect(mail.from).to have(1).items
      expect(mail.from).to include(node.sender_email)
      expect(mail.to).to have(1).items
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end
  end
end
