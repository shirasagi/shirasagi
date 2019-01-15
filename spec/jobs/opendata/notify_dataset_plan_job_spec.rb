require 'spec_helper'

describe Opendata::NotifyDatasetPlanJob, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let!(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }

  describe "update_plan_date not set" do
    let(:dataset) {
      create(
        :opendata_dataset,
        cur_node: node,
      )
    }

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      dataset

      described_class.bind(site_id: site.id).perform_now
      mail = ActionMailer::Base.deliveries.first
      expect(mail.blank?).to be true
    end
  end

  describe "update_plan_date today" do
    let(:dataset1) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "update per year",
        update_plan_mail_state: "enabled",
        update_plan_date: Time.zone.today
      )
    }
    let(:dataset2) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "update per year",
        update_plan_mail_state: "disabled",
        update_plan_date: Time.zone.today
      )
    }

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      dataset1
      dataset2

      described_class.bind(site_id: site.id).perform_now
      mail = ActionMailer::Base.deliveries.first

      expect(mail.decoded.to_s).to include(dataset1.private_show_path)
      expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
    end
  end

  describe "update_plan_date tomorrow" do
    let(:dataset) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "update per year",
        update_plan_mail_state: "enabled",
        update_plan_date: Time.zone.tomorrow
      )
    }

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      dataset

      described_class.bind(site_id: site.id).perform_now
      mail = ActionMailer::Base.deliveries.first
      expect(mail.blank?).to be true
    end
  end

  describe "update_plan_date next year" do
    let(:dataset1) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date: Time.zone.now.advance(years: 1),
        update_plan_unit: "yearly"
      )
    }
    let(:dataset2) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date:  Time.zone.now.advance(years: 2),
        update_plan_unit: "yearly",
      )
    }
    let(:dataset3) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date:  Time.zone.now.advance(years: 3),
        update_plan_unit: "yearly",
      )
    }
    let(:dataset4) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date:  Time.zone.now.advance(years: 1).tomorrow,
        update_plan_unit: "yearly",
      )
    }
    let(:dataset5) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "disabled",
        update_plan_date:  Time.zone.now.advance(years: 1),
        update_plan_unit: "yearly",
      )
    }

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      described_class.bind(site_id: site.id).perform_now
      mail = ActionMailer::Base.deliveries.first

      expect(mail.decoded.to_s).to include(dataset1.private_show_path)
      expect(mail.decoded.to_s).to include(dataset2.private_show_path)
      expect(mail.decoded.to_s).to include(dataset3.private_show_path)
      expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
      expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
    end
  end

  describe "update_plan_date other month" do
    let(:dataset1) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: Time.zone.now.advance(months: 1),
        update_plan_unit: "monthly"
      )
    }
    let(:dataset2) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: Time.zone.now.advance(months: 2),
        update_plan_unit: "monthly",
      )
    }
    let(:dataset3) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: Time.zone.now.advance(years: 1),
        update_plan_unit: "monthly",
      )
    }
    let(:dataset4) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: Time.zone.now.advance(months: 1).tomorrow,
        update_plan_unit: "monthly",
      )
    }
    let(:dataset5) {
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "disabled",
        update_plan_date: Time.zone.now.advance(months: 1),
        update_plan_unit: "monthly",
      )
    }

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      described_class.bind(site_id: site.id).perform_now
      mail = ActionMailer::Base.deliveries.first

      expect(mail.decoded.to_s).to include(dataset1.private_show_path)
      expect(mail.decoded.to_s).to include(dataset2.private_show_path)
      expect(mail.decoded.to_s).to include(dataset3.private_show_path)
      expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
      expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
    end
  end
end
