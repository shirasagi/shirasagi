require 'spec_helper'

describe MailPage::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create :mail_page_node_page, layout: layout, mail_page_category_ids: category_ids,
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["sample@example.jp"]
  end
  let!(:cate1) { create :category_node_node, site: site }
  let!(:cate2) { create :category_node_page, site: site, cur_node: cate1 }
  let!(:cate3) { create :category_node_page, site: site, cur_node: cate1 }

  let!(:utf_8_eml) do
    data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/basic/UTF-8.eml")
    SS::MailHandler.write_eml(data, "mail_page")
  end

  context "empty categories" do
    let!(:category_ids) { [] }

    it do
      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later(utf_8_eml)
      end
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(MailPage::Page.site(site).count).to eq 1
      expect(MailPage::Page.site(site).first.category_ids).to be_blank
    end
  end

  context "set categories" do
    let!(:category_ids) { [cate2.id, cate3.id] }

    it do
      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later(utf_8_eml)
      end
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(MailPage::Page.site(site).count).to eq 1
      expect(MailPage::Page.site(site).first.category_ids).to match_array category_ids
    end
  end
end
