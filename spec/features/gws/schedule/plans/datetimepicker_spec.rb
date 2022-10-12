require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:new_path) { new_gws_schedule_plan_path site }

  before do
    gws_user.update(lang: "ja")
    login_gws_user
  end

  context "datetime" do
    let(:format) { I18n.t("time.formats.picker") }

    context "valid format" do
      context "2022/1/1 12:00" do
        let(:start_at) { "2022/1/1 12:00" }
        let(:datetime) { Time.zone.parse("2022/1/1 12:00").strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end

      context "20２３/1/1 12:00" do
        let(:start_at) { "20２３/1/1 12:00" }
        let(:datetime) { Time.zone.parse("2023/1/1 12:00").strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end

      context "2022/1/1" do
        let(:start_at) { "2022/1/1" }
        let(:datetime) { Time.zone.parse("2022/1/1 00:00").strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end
    end

    context "invalid format" do
      context "*" do
        let(:start_at) { "*" }
        let(:datetime) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end

      context "*/*" do
        let(:start_at) { "*/*" }
        let(:datetime) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end

      context "*/*/*" do
        let(:start_at) { "*/*/*" }
        let(:datetime) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end

      context "*/*/*:" do
        let(:start_at) { "*/*/*:" }
        let(:datetime) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end

      context "*/*/* *:*" do
        let(:start_at) { "*/*/* *:*" }
        let(:datetime) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end

      context "2022/1/2012:00" do
        let(:start_at) { "2022/1/2012:00" }
        let(:datetime) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[start_at]", with: start_at
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_at]")).to eq datetime
          end
        end
      end
    end
  end

  context "date" do
    let(:format) { I18n.t("date.formats.picker") }

    context "valid format" do
      context "2022/1/1" do
        let(:start_on) { "2022/1/1" }
        let(:date) { Time.zone.parse("2022/1/1").strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            check "item_allday"
            fill_in "item[start_on]", with: start_on
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_on]", date: true)).to eq date
          end
        end
      end

      context "20２３/1/1" do
        let(:start_on) { "20２３/1/1" }
        let(:date) { Time.zone.parse("2023/1/1").strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            check "item_allday"
            fill_in "item[start_on]", with: start_on
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_on]", date: true)).to eq date
          end
        end
      end

      context "2022/1/1 00:00" do
        let(:start_on) { "2022/1/1 00:00" }
        let(:date) { Time.zone.parse("2022/1/1").strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            check "item_allday"
            fill_in "item[start_on]", with: start_on
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_on]", date: true)).to eq date
          end
        end
      end
    end

    context "invalid format" do
      context "*" do
        let(:start_on) { "*" }
        let(:date) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            check "item_allday"
            fill_in "item[start_on]", with: start_on
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_on]", date: true)).to eq date
          end
        end
      end

      context "*/*" do
        let(:start_on) { "*/*" }
        let(:date) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            check "item_allday"
            fill_in "item[start_on]", with: start_on
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_on]", date: true)).to eq date
          end
        end
      end

      context "*/*/*" do
        let(:start_on) { "*/*/*" }
        let(:date) { Time.zone.now.strftime(format) }

        it "#new" do
          visit new_path
          within "form#item-form" do
            check "item_allday"
            fill_in "item[start_on]", with: start_on
            fill_in "item[name]", with: unique_id
            expect(datetimepicker_value("item[start_on]", date: true)).to eq date
          end
        end
      end
    end
  end
end
