require 'spec_helper'

describe MailPage::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create :mail_page_node_page, layout: layout, mail_page_removal_state: mail_page_removal_state,
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["sample@example.jp"]
  end
  let!(:utf_8_eml) do
    data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/basic/UTF-8.eml")
    SS::MailHandler.write_eml(data, "mail_page")
  end

  let(:now) { Time.zone.now }
  let(:page1) do
    Timecop.freeze(now.advance(years: -1)) do
      create(:mail_page_page, cur_node: node)
    end
  end
  let(:page2) do
    Timecop.freeze(now.advance(weeks: -1, hours: 1)) do
      create(:mail_page_page, cur_node: node)
    end
  end
  let(:page3) do
    Timecop.freeze(now.advance(days: -1, hours: 1)) do
      create(:mail_page_page, cur_node: node)
    end
  end

  context "removal state none" do
    let!(:mail_page_removal_state) { "none" }

    it do
      page1
      page2
      page3
      expect(MailPage::Page.site(site).count).to eq 3

      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later(utf_8_eml)
      end
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(MailPage::Page.site(site).count).to eq 4
      expect(MailPage::Page.site(site).pluck(:name)).to match_array [page1.name, page2.name, page3.name, "UTF-8"]

    end
  end

  context "removal state 1week" do
    let!(:mail_page_removal_state) { "1.week" }

    it do
      page1
      page2
      page3
      expect(MailPage::Page.site(site).count).to eq 3

      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later(utf_8_eml)
      end
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(MailPage::Page.site(site).count).to eq 3
      expect(MailPage::Page.site(site).pluck(:name)).to match_array [page2.name, page3.name, "UTF-8"]
    end
  end

  context "removal state 1day" do
    let!(:mail_page_removal_state) { "1.day" }

    it do
      page1
      page2
      page3
      expect(MailPage::Page.site(site).count).to eq 3

      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later(utf_8_eml)
      end
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(MailPage::Page.site(site).count).to eq 2
      expect(MailPage::Page.site(site).pluck(:name)).to match_array [page3.name, "UTF-8"]
    end
  end
end
