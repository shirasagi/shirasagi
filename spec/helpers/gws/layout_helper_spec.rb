require 'spec_helper'

describe Gws::LayoutHelper, type: :helper, dbscope: :example do
  before do
    helper.instance_variable_set :@cur_user, gws_user
    helper.instance_variable_set :@cur_site, gws_site
  end

  describe "category_label_css" do
    let(:item) { create :gws_board_category, color: '#000000' }

    it do
      html = helper.category_label_css(item)
      expect(html).to eq "background-color: #000000; color: #ffffff;"
    end
  end

  describe "gws_help_icon" do
    let(:url) { "https://example.jp/manual.pdf" }

    it "outputs nothing when description and url are both blank" do
      expect(helper.gws_help_icon("", manual_url: "", manual_label: "M")).to eq ""
      expect(helper.gws_help_icon(nil, manual_url: nil, manual_label: "M")).to eq ""
    end

    it "renders the dropdown structure" do
      doc = Capybara.string(helper.gws_help_icon("説明", manual_url: url, manual_label: "マニュアル"))
      expect(doc).to have_css("span.dropdown.dropdown-toggle.gws-menu-help")
      expect(doc).to have_css("button.gws-menu-help__icon")
      expect(doc).to have_css(".dropdown-menu.gws-menu-help-popup")
    end

    it "renders the description only (no manual link)" do
      doc = Capybara.string(helper.gws_help_icon("説明文", manual_url: nil, manual_label: "M"))
      expect(doc).to have_css(".gws-menu-help-popup__desc", text: "説明文")
      expect(doc).to have_no_css(".gws-menu-help-popup__manual")
    end

    it "renders the manual link only (no description)" do
      doc = Capybara.string(helper.gws_help_icon(nil, manual_url: url, manual_label: "マニュアル"))
      expect(doc).to have_no_css(".gws-menu-help-popup__desc")
      expect(doc).to have_css(".gws-menu-help-popup__manual a", text: "マニュアル")
    end

    it "renders both the description and the manual link" do
      doc = Capybara.string(helper.gws_help_icon("説明", manual_url: url, manual_label: "マニュアル"))
      expect(doc).to have_css(".gws-menu-help-popup__desc", text: "説明")
      expect(doc).to have_css(".gws-menu-help-popup__manual a", text: "マニュアル")
    end

    it "routes the manual link through sns_redirect_path with target/rel" do
      doc = Capybara.string(helper.gws_help_icon("説明", manual_url: url, manual_label: "マニュアル"))
      link = doc.find(".gws-menu-help-popup__manual a")
      expect(link[:href]).to eq helper.sns_redirect_path(ref: url)
      expect(link[:target]).to eq "_blank"
      expect(link[:rel]).to eq "noopener"
    end

    it "escapes the description and the manual label" do
      html = helper.gws_help_icon("<script>x</script>", manual_url: url, manual_label: "<b>L</b>")
      expect(html).to include("&lt;script&gt;x&lt;/script&gt;")
      expect(html).not_to include("<script>x</script>")
      expect(html).to include("&lt;b&gt;L&lt;/b&gt;")
    end
  end
end
