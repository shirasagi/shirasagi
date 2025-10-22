require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) { create(:inquiry_node_form, site: site, layout_id: layout.id, inquiry_captcha: "disabled") }

  let!(:column0_options) { Array.new(3) { |i| "column0-#{i}" } }
  let!(:column2_options) { Array.new(3) { |i| "column2-#{i}" } }
  let!(:column4_options) { Array.new(3) { |i| "column4-#{i}" } }

  let!(:column0) do
    create :inquiry_column_radio, site: site, node: node, order: 1, select_options: column0_options,
      name: 'column0'
  end
  let!(:section1) do
    create(:inquiry_column_section, site: site, node: node, order: 10)
  end
  let!(:column1) do
    create :inquiry_column_name, site: site, node: node, order: 11, required: "required"
  end
  let!(:section2) do
    create(:inquiry_column_section, site: site, node: node, order: 20)
  end
  let!(:column2) do
    create :inquiry_column_radio, site: site, node: node, order: 21, select_options: column2_options,
      name: 'column2'
  end
  let!(:section3) do
    create(:inquiry_column_section, site: site, node: node, order: 30)
  end
  let!(:column3) do
    create :inquiry_column_name, site: site, node: node, order: 31, required: "required"
  end
  let!(:section4) do
    create(:inquiry_column_section, site: site, node: node, order: 40)
  end
  let!(:column4) do
    create :inquiry_column_radio, site: site, node: node, order: 41, select_options: column4_options,
      name: 'column4'
  end
  let!(:section5) do
    create(:inquiry_column_section, site: site, node: node, order: 50)
  end
  let!(:column5) do
    create :inquiry_column_name, site: site, node: node, order: 51, required: "required"
  end
  let!(:section6) do
    create(:inquiry_column_section, site: site, node: node, order: 60)
  end
  let!(:column6) do
    create :inquiry_column_name, site: site, node: node, order: 61, required: "required"
  end

  before do
    Capybara.app_host = "http://#{site.domain}"

    column0.branch_section_ids = [section1.id.to_s, section2.id.to_s, ""]
    column0.save
    column2.branch_section_ids = [section3.id.to_s, section4.id.to_s, ""]
    column2.save
    column4.branch_section_ids = [section5.id.to_s, section6.id.to_s, ""]
    column4.save
  end

  context "with section", js: true do
    it do
      visit node.url

      within ".inquiry-form" do
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column0_options[0]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column0_options[1]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column2_options[0]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column2_options[1]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column4_options[0]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column4_options[1]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: true)

        ## back to column0
        choose column0_options[0]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        ## retry
        choose column0_options[1]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column2_options[1]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column4_options[0]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        click_on I18n.t("inquiry.confirm")
      end
      expect(page).to have_css(".errorExplanation")

      ## retry
      within ".inquiry-form" do
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: false)

        choose column0_options[1]
        choose column2_options[1]
        choose column4_options[1]
        expect(page).to have_css("fieldset.section-#{section1.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section2.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section3.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section4.id}", visible: true)
        expect(page).to have_css("fieldset.section-#{section5.id}", visible: false)
        expect(page).to have_css("fieldset.section-#{section6.id}", visible: true)

        fill_in "item[#{column6.id}]", with: 'string'
        click_on I18n.t("inquiry.confirm")
      end
      expect(page).not_to have_css(".errorExplanation")

      # confirm
      click_on I18n.t("inquiry.submit")
      expect(page).to have_css(".inquiry-sent")

      # database
      Inquiry::Answer.first.data.tap do |data|
        expect(data[0].value).to eq column0_options[1]
        expect(data[1].value).to eq ''
        expect(data[2].value).to eq ''
        expect(data[3].value).to eq ''
        expect(data[4].value).to eq column2_options[1]
        expect(data[5].value).to eq ''
        expect(data[6].value).to eq ''
        expect(data[7].value).to eq ''
        expect(data[8].value).to eq column4_options[1]
        expect(data[9].value).to eq ''
        expect(data[10].value).to eq ''
        expect(data[11].value).to eq ''
        expect(data[12].value).to eq 'string'
      end
    end
  end
end
