require 'spec_helper'

describe "facility_node_pages", type: :feature, dbscope: :example, js: true do
  context "with basic configuration" do
    let!(:site) { cms_site }
    let!(:node) { create :facility_node_node }
    let!(:category_node) { create :facility_node_category, cur_node: node }
    let!(:location_node) { create :facility_node_location, cur_node: node }
    let!(:service_node) { create :facility_node_service, cur_node: node }

    before do
      node.st_category_ids = [ category_node.id ]
      node.st_location_ids = [ location_node.id ]
      node.st_service_ids = [ service_node.id ]
      node.save!

      login_cms_user
    end

    context "basic crud" do
      let(:name) { unique_id }
      let(:basename) { unique_id }
      let(:kana) { ss_japanese_text }
      let(:postcode) { unique_id }
      let(:address) { unique_id }
      let(:tel) { unique_id }
      let(:fax) { unique_id }
      let(:related_url) { "/#{unique_id}/" }
      let(:additional_info_field) { unique_id }
      let(:additional_info_value) { Array.new(2) { unique_id } }
      let(:sort) { %w(name filename created updated_desc released_desc order order_desc).sample }
      let(:sort_label) { I18n.t("cms.sort_options.#{sort}.title") }
      let(:limit) { rand(20..100) }
      let(:upper_html) { "<div class=\"upper\">upper</div>" }
      let(:loop_html) { "<div class=\"loop\">loop</div>" }
      let(:lower_html) { "<div class=\"lower\">lower</div>" }
      let(:new_days) { rand(1..20) }
      let(:name2) { "modify" }

      it do
        visit facility_pages_path(site: site, cid: node)

        #
        # Create Facility::Node::Page
        #
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[basename]", with: basename

          # addon-facility-agents-addons-body
          fill_in "item[kana]", with: kana
          fill_in "item[postcode]", with: postcode
          fill_in "item[address]", with: address
          fill_in "item[tel]", with: tel
          fill_in "item[fax]", with: fax
          fill_in "item[related_url]", with: related_url

          # addon-cms-agents-addons-additional_info
          fill_in "item[additional_info][][field]", with: additional_info_field
          fill_in "item[additional_info][][value]", with: additional_info_value.join("\n")

          # addon-facility-agents-addons-category
          check "item_category_ids_#{category_node.id}"

          # addon-facility-agents-addons-service
          check "item_service_ids_#{service_node.id}"

          # addon-facility-agents-addons-location
          check "item_location_ids_#{location_node.id}"

          # addon-facility-agents-addons-notice
          select sort_label, from: "item[sort]"
          fill_in "item[limit]", with: limit
          fill_in_code_mirror "item[upper_html]", with: upper_html
          fill_in_code_mirror "item[loop_html]", with: loop_html
          fill_in_code_mirror "item[lower_html]", with: lower_html
          fill_in "item[new_days]", with: new_days

          # addon-cms-agents-addons-form-node

          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_no_css("form#item-form")

        expect(Facility::Node::Page.all.count).to eq 1
        page_node = Facility::Node::Page.all.first
        expect(page_node.name).to eq name
        expect(page_node.basename).to eq basename
        expect(page_node.filename).to eq "#{node.filename}/#{basename}"
        # addon-facility-agents-addons-body
        expect(page_node.kana).to eq kana
        expect(page_node.postcode).to eq postcode
        expect(page_node.address).to eq address
        expect(page_node.tel).to eq tel
        expect(page_node.fax).to eq fax
        expect(page_node.related_url).to eq related_url
        # addon-cms-agents-addons-additional_info
        expect(page_node.additional_info.length).to eq 1
        expect(page_node.additional_info[0][:field]).to eq additional_info_field
        expect(page_node.additional_info[0][:value]).to eq additional_info_value.join("\r\n")
        # addon-facility-agents-addons-category
        expect(page_node.category_ids).to eq [ category_node.id ]
        # addon-facility-agents-addons-service
        expect(page_node.service_ids).to eq [ service_node.id ]
        # addon-facility-agents-addons-location
        expect(page_node.location_ids).to eq [ location_node.id ]
        # addon-facility-agents-addons-notice
        expect(page_node.sort).to eq sort.sub("_desc", " -1")
        expect(page_node.limit).to eq limit
        expect(page_node.upper_html).to eq upper_html
        expect(page_node.loop_html).to eq loop_html
        expect(page_node.lower_html).to eq lower_html
        expect(page_node.new_days).to eq new_days

        visit facility_pages_path(site.id, node)
        click_on name
        expect(page).to have_css("#facility-info", text: name)

        #
        # Update Facility::Node::Page
        #
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[name]", with: name2
          click_button I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        page_node.reload
        expect(page_node.name).to eq name2

        #
        # Delete Facility::Node::Page
        #
        visit facility_pages_path(site.id, node)
        click_on name2
        click_on I18n.t("ss.links.delete")
        within "form" do
          click_on I18n.t('ss.buttons.delete')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

        expect { page_node.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    describe "#import" do
      it do
        visit import_facility_pages_path(site: site, cid: node)

        within "form#task-form" do
          attach_file "item[file]", "#{Rails.root}/spec/fixtures/facility/facility.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end
        expect(page).to have_content I18n.t("ss.notice.started_import")

        expect(SS::File.all.count).to eq 1
        file = SS::File.all.first
        expect(file.name).to eq "facility.csv"
        expect(file.filename).to eq "facility.csv"
        expect(file.size).to be > 0
        expect(file.owner_item_type).to be_blank
        expect(file.owner_item_id).to be_blank

        expect(enqueued_jobs.length).to eq 1
        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:job]).to eq Facility::ImportJob
          expect(enqueued_job[:args]).to eq [ file.id ]
          expect(enqueued_job[:at]).to be_blank
        end
      end
    end
  end

  context "able to create under cms/node" do
    let!(:site) { cms_site }
    let!(:node) { create :cms_node }

    before do
      login_cms_user
    end

    it do
      visit facility_pages_path(site: site, cid: node)

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_no_css("form#item-form")

      expect(Facility::Node::Page.all.count).to eq 1
      page_node = Facility::Node::Page.all.first
      expect(page_node.name).to eq "sample"
      expect(page_node.basename).to eq "sample"
      expect(page_node.filename).to eq "#{node.filename}/sample"
    end
  end
end
