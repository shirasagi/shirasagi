require 'spec_helper'

describe Opendata::NotifyDatasetPlanJob, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let!(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }

  describe "update_plan_date not set" do
    let(:today) { Date.parse("2019/2/25") }
    let(:dataset) { create(:opendata_dataset, cur_node: node) }

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it "with yesterday" do
      dataset

      Timecop.travel(today.yesterday) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with today" do
      dataset

      described_class.bind(site_id: site.id).perform_now
      mail = ActionMailer::Base.deliveries.first
      expect(mail.blank?).to be true
    end

    it "with tomorrow" do
      dataset

      Timecop.travel(today.tomorrow) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with next month" do
      dataset

      Timecop.travel(today.next_month) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with next year" do
      dataset

      Timecop.travel(today.next_year) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end
  end

  describe "update_plan_date today" do
    let(:today) { Date.parse("2019/2/25") }
    let(:dataset1) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "update per year",
        update_plan_mail_state: "enabled",
        update_plan_date: today
      )
    end
    let(:dataset2) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "update per year",
        update_plan_mail_state: "disabled",
        update_plan_date: today
      )
    end

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it "with next yesterday" do
      dataset1
      dataset2

      Timecop.travel(today.yesterday) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with today" do
      dataset1
      dataset2

      Timecop.travel(today) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
      end
    end

    it "with tomorrow" do
      dataset1
      dataset2

      Timecop.travel(today.tomorrow) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with next month" do
      dataset1
      dataset2

      Timecop.travel(today.next_month) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with next year" do
      dataset1
      dataset2

      Timecop.travel(today.next_year) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end
  end

  describe "update_plan_date tomorrow" do
    let(:today) { Date.parse("2019/2/25") }
    let(:dataset) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "update per year",
        update_plan_mail_state: "enabled",
        update_plan_date: today.tomorrow
      )
    end

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it "with yesterday" do
      dataset

      Timecop.travel(today.yesterday) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with today" do
      dataset

      Timecop.travel(today) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with tomorrow" do
      dataset

      Timecop.travel(today.tomorrow) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset.private_show_path)
      end
    end

    it "with next month" do
      dataset

      Timecop.travel(today.next_month) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with next year" do
      dataset

      Timecop.travel(today.next_year) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end
  end

  describe "update_plan_date yearly" do
    let(:today) { Date.parse("2019/2/25") }
    let(:dataset1) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date: today.advance(years: 1),
        update_plan_unit: "yearly"
      )
    end
    let(:dataset2) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date: today.advance(years: 2),
        update_plan_unit: "yearly"
      )
    end
    let(:dataset3) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date: today.advance(years: 3),
        update_plan_unit: "yearly"
      )
    end
    let(:dataset4) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "enabled",
        update_plan_date: today.advance(years: 1).tomorrow,
        update_plan_unit: "yearly"
      )
    end
    let(:dataset5) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "yearly",
        update_plan_mail_state: "disabled",
        update_plan_date: today.advance(years: 1),
        update_plan_unit: "yearly"
      )
    end

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it "with yesterday" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.yesterday) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with today" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with tomorrow" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.tomorrow) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with next year" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.next_year) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first

        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with two years later" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.advance(years: 2)) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first

        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with three years later" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.advance(years: 3)) do
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

  describe "update_plan_date monthly" do
    let(:today) { Date.parse("2019/1/31") }
    let(:today_1m_later) { Date.parse("2019/2/28") }
    let(:today_2m_later) { Date.parse("2019/3/31") }
    let(:today_1y_later) { Date.parse("2020/1/31") }
    let(:other_day) { Date.parse("2019/1/15") }

    let(:dataset1) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_1m_later,
        update_plan_unit: "monthly"
      )
    end
    let(:dataset2) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_2m_later,
        update_plan_unit: "monthly"
      )
    end
    let(:dataset3) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_1y_later,
        update_plan_unit: "monthly"
      )
    end
    let(:dataset4) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: other_day,
        update_plan_unit: "monthly"
      )
    end
    let(:dataset5) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "disabled",
        update_plan_date: today_1m_later,
        update_plan_unit: "monthly"
      )
    end

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it "with yesterday" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.yesterday) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with today" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with tomorrow" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.tomorrow) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 1 month laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2019/2/28")) do #2019/2/28
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path) #2019/2/28
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path) #2019/3/31
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path) #2020/1/31
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 2 months laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2019/3/28")) do #2019/3/28
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path) #2019/2/28
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path) #2019/3/31
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path) #2020/1/31
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end

      ActionMailer::Base.deliveries.clear

      Timecop.travel(Date.parse("2019/3/31")) do #2019/3/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).not_to include(dataset1.private_show_path) #2019/2/28
        expect(mail.decoded.to_s).to include(dataset2.private_show_path) #2019/3/31
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path) #2020/1/31
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 1 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2020/1/28")) do #2020/1/28
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path) #2019/2/28
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path) #2019/3/31
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path) #2020/1/31
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end

      ActionMailer::Base.deliveries.clear

      Timecop.travel(Date.parse("2020/1/31")) do #2020/1/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).not_to include(dataset1.private_show_path) #2019/2/28
        expect(mail.decoded.to_s).to include(dataset2.private_show_path) #2019/3/31
        expect(mail.decoded.to_s).to include(dataset3.private_show_path) #2020/1/31
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 1 year and 1 month laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2020/2/28")) do #2020/2/28
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path) #2019/2/28
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path) #2019/3/31
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path) #2020/1/31
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end

      ActionMailer::Base.deliveries.clear

      Timecop.travel(Date.parse("2020/2/29")) do #2020/2/29
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).not_to include(dataset1.private_show_path) #2019/2/28
        expect(mail.decoded.to_s).to include(dataset2.private_show_path) #2019/3/31
        expect(mail.decoded.to_s).to include(dataset3.private_show_path) #2020/1/31
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end
  end

  describe "update_plan_date quarterly" do
    let(:today) { Date.parse("2019/10/31") }
    let(:today_1m_later) { Date.parse("2019/11/30") }
    let(:other_day) { Date.parse("2019/1/15") }

    let(:dataset1) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_1m_later,
        update_plan_unit: "quarterly"
      )
    end
    let(:dataset2) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: other_day,
        update_plan_unit: "quarterly"
      )
    end

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it "with yesterday" do
      dataset1
      dataset2

      Timecop.travel(today.yesterday) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with today" do
      dataset1
      dataset2

      Timecop.travel(today) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with tomorrow" do
      dataset1
      dataset2

      Timecop.travel(today.tomorrow) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 1 month laster" do
      dataset1
      dataset2

      Timecop.travel(Date.parse("2019/11/30")) do #2019/11/30
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path) #2019/11/30
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
      end
    end

    it "with 2 months laster" do
      dataset1
      dataset2

      Timecop.travel(Date.parse("2019/12/31")) do #2019/12/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 3 months laster" do
      dataset1
      dataset2

      Timecop.travel(Date.parse("2020/1/31")) do #2020/1/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 4 months laster" do
      dataset1
      dataset2

      Timecop.travel(Date.parse("2020/2/29")) do #2020/2/29
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path) #2019/11/30
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
      end
    end

    it "with 5 months laster" do
      dataset1
      dataset2

      Timecop.travel(Date.parse("2020/3/31")) do #2020/3/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 6 months laster" do
      dataset1
      dataset2

      Timecop.travel(Date.parse("2020/4/30")) do #2020/4/30
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 7 months laster" do
      dataset1
      dataset2

      Timecop.travel(Date.parse("2020/5/30")) do #2020/5/30
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path) #2019/11/30
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
      end

      ActionMailer::Base.deliveries.clear

      Timecop.travel(Date.parse("2020/5/31")) do #2020/5/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end
  end

  describe "update_plan_date two_yearly" do
    let(:today) { Date.parse("2019/10/31") }
    let(:today_1y_later) { Date.parse("2020/10/31") }
    let(:other_day) { Date.parse("2020/10/15") }

    let(:dataset1) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_1y_later,
        update_plan_unit: "two_yearly"
      )
    end
    let(:dataset2) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_1y_later,
        update_plan_unit: "three_yearly"
      )
    end
    let(:dataset3) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_1y_later,
        update_plan_unit: "four_yearly"
      )
    end
    let(:dataset4) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: today_1y_later,
        update_plan_unit: "five_yearly"
      )
    end
    let(:dataset5) do
      create(
        :opendata_dataset,
        cur_node: node,
        update_plan: "monthly",
        update_plan_mail_state: "enabled",
        update_plan_date: other_day,
        update_plan_unit: "two_yearly"
      )
    end

    before do
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it "with yesterday" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.yesterday) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with today" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with tomorrow" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(today.tomorrow) do
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 1 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2020/10/31")) do #2020/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 2 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2021/10/31")) do #2021/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 3 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2022/10/31")) do #2022/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 4 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2023/10/31")) do #2021/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).not_to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 5 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2024/10/31")) do #2024/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 6 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2025/10/31")) do #2021/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).not_to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 7 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2026/10/31")) do #2026/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end

    it "with 8 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2027/10/31")) do #2021/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.blank?).to be true
      end
    end

    it "with 9 year laster" do
      dataset1
      dataset2
      dataset3
      dataset4
      dataset5

      Timecop.travel(Date.parse("2028/10/31")) do #2028/10/31
        described_class.bind(site_id: site.id).perform_now
        mail = ActionMailer::Base.deliveries.first
        expect(mail.decoded.to_s).to include(dataset1.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset2.private_show_path)
        expect(mail.decoded.to_s).to include(dataset3.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset4.private_show_path)
        expect(mail.decoded.to_s).not_to include(dataset5.private_show_path)
      end
    end
  end
end
