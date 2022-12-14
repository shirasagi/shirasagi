require 'spec_helper'

describe Cms::Page::ExpirationNoticeJob, dbscope: :example do
  let!(:site) { cms_site }
  let(:mypage_scheme) { %w(http https).sample }
  let(:mypage_domain) { unique_domain }
  let(:expiration_before) { "90.days" }

  before do
    ActionMailer::Base.deliveries = []

    site.mypage_scheme = mypage_scheme
    site.mypage_domain = mypage_domain
    site.page_expiration_state = expiration_state
    site.page_expiration_before = expiration_before
    site.save!
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "when page_expiration_state is disabled" do
    let(:expiration_state) { "disabled" }

    it do
      described_class.bind(site_id: site).perform_now

      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(/公開期限警告が無効です。/)
      end
    end
  end

  context "when page_expiration_state is enabled" do
    let(:expiration_state) { "enabled" }
    let(:group1) do
      create(
        :cms_group, name: "#{site.groups.first.name}/#{unique_id}",
        contact_groups: [{ main_state: "main", name: unique_id, contact_email: unique_email }]
      )
    end
    let(:group2) do
      create(
        :cms_group, name: "#{site.groups.first.name}/#{unique_id}",
        contact_groups: [{ main_state: "main", name: unique_id, contact_email: unique_email }]
      )
    end
    let(:group3) do
      create(
        :cms_group, name: "#{site.groups.first.name}/#{unique_id}",
        contact_groups: [{ main_state: "main", name: unique_id, contact_email: unique_email }]
      )
    end

    context "with cms/page on root" do
      let!(:page1) do
        create(:cms_page, cur_site: site, group_ids: [ group1.id ])
      end
      let!(:page2) do
        Timecop.travel(Time.zone.now - SS::Duration.parse(expiration_before) - 1.day) do
          create(:cms_page, cur_site: site, group_ids: [ group2.id ])
        end
      end
      let!(:page3) do
        Timecop.travel(Time.zone.now - SS::Duration.parse(expiration_before) - 1.day) do
          create(:cms_page, cur_site: site, group_ids: [ group3.id ], state: "closed")
        end
      end

      it do
        described_class.bind(site_id: site).perform_now

        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/公開期限警告が無効です。/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.each do |mail|
          expect(mail).not_to be_nil
          expect(mail.from.first).to eq SS.config.mail.default_from
          expect(mail.subject).to eq I18n.t("cms.page_expiration_mail.default_subject")
          expect(mail.body.raw_source).to include(*I18n.t("cms.page_expiration_mail.default_upper_text"))
          expect(mail.body.raw_source).to include(page2.name, page2.private_show_path)
        end
      end
    end

    context "with cms/page blow folder" do
      let!(:node) { create :cms_node_page, cur_site: site, group_ids: [ group1.id, group2.id ] }
      let!(:page1) do
        create(:cms_page, cur_site: site, cur_node: node, group_ids: [ group1.id ])
      end
      let!(:page2) do
        Timecop.travel(Time.zone.now - SS::Duration.parse(expiration_before) - 1.day) do
          create(:cms_page, cur_site: site, cur_node: node, group_ids: [ group2.id ])
        end
      end
      let!(:page3) do
        Timecop.travel(Time.zone.now - SS::Duration.parse(expiration_before) - 1.day) do
          create(:cms_page, cur_site: site, cur_node: node, group_ids: [ group3.id ], state: "closed")
        end
      end

      it do
        described_class.bind(site_id: site).perform_now

        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/公開期限警告が無効です。/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.each do |mail|
          expect(mail).not_to be_nil
          expect(mail.from.first).to eq SS.config.mail.default_from
          expect(mail.subject).to eq I18n.t("cms.page_expiration_mail.default_subject")
          expect(mail.body.raw_source).to include(*I18n.t("cms.page_expiration_mail.default_upper_text"))
          expect(mail.body.raw_source).to include(page2.name, page2.private_show_path)
        end
      end
    end

    context "with article/page blow folder" do
      let!(:node) { create :article_node_page, cur_site: site, group_ids: [ group1.id, group2.id ] }
      let!(:page1) do
        create(:article_page, cur_site: site, cur_node: node, group_ids: [ group1.id ])
      end
      let!(:page2) do
        Timecop.travel(Time.zone.now - SS::Duration.parse(expiration_before) - 1.day) do
          create(:article_page, cur_site: site, cur_node: node, group_ids: [ group2.id ])
        end
      end
      let!(:page3) do
        Timecop.travel(Time.zone.now - SS::Duration.parse(expiration_before) - 1.day) do
          create(:article_page, cur_site: site, cur_node: node, group_ids: [ group3.id ], state: "closed")
        end
      end

      it do
        described_class.bind(site_id: site).perform_now

        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/公開期限警告が無効です。/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        ActionMailer::Base.deliveries.each do |mail|
          expect(mail).not_to be_nil
          expect(mail.from.first).to eq SS.config.mail.default_from
          expect(mail.subject).to eq I18n.t("cms.page_expiration_mail.default_subject")
          expect(mail.body.raw_source).to include(*I18n.t("cms.page_expiration_mail.default_upper_text"))
          expect(mail.body.raw_source).to include(page2.name, page2.private_show_path)
        end
      end
    end
  end
end
