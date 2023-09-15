require 'spec_helper'

describe SS::LiquidFilters, dbscope: :example do
  let(:site) { cms_site }
  let(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
  let(:column) { create(:cms_column_text_field, cur_site: site, name: "column1", cur_form: form, required: 'optional') }
  let(:column_values1) { [ column.value_type.new(column: column, value: "column_value1") ] }
  let(:column_values2) { [ column.value_type.new(column: column, value: "column_value2") ] }
  let(:column_values3) { [ column.value_type.new(column: column, value: "column_value3") ] }
  let(:node) { create :article_node_page }
  let!(:page1) do
    create :article_page, cur_site: site, cur_node: node, name: 'name', form: form, column_values: column_values1
  end
  let!(:page2) do
    create :article_page, cur_site: site, cur_node: node, name: 'name', form: form, column_values: column_values2
  end
  let!(:page3) do
    create :article_page, cur_site: site, cur_node: node, name: 'name', form: form, column_values: column_values3
  end
  let(:assigns) { { "value" => value } }
  let(:template) { Liquid::Template.parse(source) }
  subject { template.render(assigns).to_s }

  describe "ss_date" do
    let(:value) { Time.zone.now }

    context "without arguments" do
      let(:source) { "{{ value || ss_date }}" }
      it { is_expected.to eq I18n.l(value.to_date) }
    end

    context "with 'default'" do
      let(:source) { "{{ value || ss_date: 'default' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :default) }
    end

    context "with 'iso'" do
      let(:source) { "{{ value || ss_date: 'iso' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :iso) }
    end

    context "with 'long'" do
      let(:source) { "{{ value || ss_date: 'long' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :long) }
    end

    context "with 'short'" do
      let(:source) { "{{ value || ss_date: 'short' }}" }
      it { is_expected.to eq I18n.l(value.to_date, format: :short) }
    end

    context "with custom date format" do
      let(:source) { "{{ value || ss_date: '%Y/%m' }}" }
      it { is_expected.to eq value.to_date.strftime('%Y/%m') }
    end

    context "with custom date format (wday)" do
      context "%a" do
        let(:source) { "{{ value || ss_date: '%a' }}" }
        it { is_expected.to eq I18n.t("date.abbr_day_names")[value.wday] }
      end

      context "%A" do
        let(:source) { "{{ value || ss_date: '%A' }}" }
        it { is_expected.to eq I18n.t("date.day_names")[value.wday] }
      end
    end
  end

  describe "ss_time" do
    let(:value) { Time.zone.now }

    context "without arguments" do
      let(:source) { "{{ value || ss_time }}" }
      it { is_expected.to eq I18n.l(value) }
    end

    context "with 'default'" do
      let(:source) { "{{ value || ss_time: 'default' }}" }
      it { is_expected.to eq I18n.l(value, format: :default) }
    end

    context "with 'iso'" do
      let(:source) { "{{ value || ss_time: 'iso' }}" }
      it { is_expected.to eq I18n.l(value, format: :iso) }
    end

    context "with 'long'" do
      let(:source) { "{{ value || ss_time: 'long' }}" }
      it { is_expected.to eq I18n.l(value, format: :long) }
    end

    context "with 'short'" do
      let(:source) { "{{ value || ss_time: 'short' }}" }
      it { is_expected.to eq I18n.l(value, format: :short) }
    end

    context "with custom date format" do
      let(:source) { "{{ value || ss_time: '%F %j' }}" }
      it { is_expected.to eq value.strftime('%F %j') }
    end

    context "with custom date format (wday)" do
      context "%a" do
        let(:source) { "{{ value || ss_time: '%a' }}" }
        it { is_expected.to eq I18n.t("date.abbr_day_names")[value.wday] }
      end

      context "%A" do
        let(:source) { "{{ value || ss_time: '%A' }}" }
        it { is_expected.to eq I18n.t("date.day_names")[value.wday] }
      end
    end
  end

  describe "delimited" do
    let(:source) { "{{ value || delimited }}" }

    context "with 0" do
      let(:value) { 0 }
      it { is_expected.to eq "0" }
    end

    context "with 1" do
      let(:value) { 1 }
      it { is_expected.to eq "1" }
    end

    context "with -1" do
      let(:value) { -1 }
      it { is_expected.to eq "-1" }
    end

    context "with 2756" do
      let(:value) { 2_756 }
      it { is_expected.to eq "2,756" }
    end

    context "with - 2756" do
      let(:value) { -2_756 }
      it { is_expected.to eq "-2,756" }
    end

    context "with integer string" do
      let(:value) { "2756" }
      it { is_expected.to eq "2,756" }
    end

    context "with float string" do
      let(:value) { "2756.98" }
      it { is_expected.to eq "2,756.98" }
    end

    context "with non-numeric string" do
      let(:value) { "hello" }
      it { is_expected.to eq "hello" }
    end
  end

  describe "human_size" do
    let(:source) { "{{ value || human_size }}" }

    context "with 0" do
      let(:value) { 0 }
      it { is_expected.to eq "0#{I18n.t("number.human.storage_units.units.byte")}" }
    end

    context "with 10" do
      let(:value) { 10 }
      it { is_expected.to eq "10#{I18n.t("number.human.storage_units.units.byte")}" }
    end

    context "with 10k" do
      let(:value) { 10 * 1_024 }
      it { is_expected.to eq "10KB" }
    end

    context "with 10M" do
      let(:value) { 10 * 1_024 * 1_024 }
      it { is_expected.to eq "10MB" }
    end

    context "with -10" do
      let(:value) { -10 }
      it { is_expected.to eq "-10#{I18n.t("number.human.storage_units.units.byte")}" }
    end

    context "with -10M" do
      let(:value) { - 10 * 1_024 * 1_024 }
      it { is_expected.to eq "-10485760バイト" }
    end
  end

  describe "ss_append" do
    let(:value) { unique_id }
    let(:appendee) { unique_id }
    let(:source) { "{{ value || ss_append: \"#{appendee}\"}}" }

    it { is_expected.to eq "#{value}#{appendee}" }
  end

  describe "ss_prepend" do
    let(:value) { unique_id }
    let(:prepend) { unique_id }
    let(:source) { "{{ value || ss_prepend: \"#{prepend}\"}}" }

    it { is_expected.to eq "#{prepend}#{value}" }
  end

  describe "ss_img_src" do
    let(:prepend) { unique_id }
    let(:source) { "{{ value || ss_img_src}}" }

    context "with blank" do
      let(:value) { "" }
      it { is_expected.to eq "" }
    end

    context "with <img>" do
      let(:value) { "<img src=\"/profile.png\">" }
      it { is_expected.to eq "/profile.png" }
    end

    context "with 2 <img>" do
      let(:value) { "<img src=\"/one.png\"><img src=\"/two.png\">" }
      it { is_expected.to eq "/one.png" }
    end
  end

  describe "expand_path" do
    let(:path) { "http://www.example.jp/" }
    let(:source) { "{{ value || expand_path: \"#{path}\"}}" }

    context "with blank" do
      let(:value) { "" }
      it { is_expected.to eq "" }
    end

    context "with relative path" do
      let(:value) { "img/cover.png" }
      it { is_expected.to eq "http://www.example.jp/img/cover.png" }
    end

    context "with absolute path" do
      let(:value) { "/img/cover.png" }
      it { is_expected.to eq "http://www.example.jp/img/cover.png" }
    end
  end

  describe "sanitize" do
    let(:source) { "{{ value || sanitize }}" }

    context "with blank" do
      let(:value) { "" }
      it { is_expected.to eq "" }
    end

    context "with some safe tags" do
      let(:value) { "<a href=\"/profile\"><img src=\"/profile.png\"></a>" }
      it { is_expected.to eq value }
    end

    context "with <script> which is unsafe" do
      let(:value) { "<script>alert('hello')</script>" }
      it { is_expected.to eq "alert('hello')" }
    end
  end

  describe "search_column_value" do
    let(:source) do
      templ = []
      templ << '{% assign column1 = value | search_column_value: "column1" %}'
      templ << '{% if column1 %}'
      templ << '<p>{{ column1.value }}</p>'
      templ << '{% endif %}'
      templ.join("\n")
    end

    context "with blank" do
      let(:value) { "" }
      it do
        is_expected.not_to include("column_value1")
        is_expected.not_to include("column_value2")
        is_expected.not_to include("column_value3")
      end
    end

    context "with page1" do
      let(:value) { page1 }
      it do
        is_expected.to include("column_value1")
        is_expected.not_to include("column_value2")
        is_expected.not_to include("column_value3")
      end
    end

    context "with page2" do
      let(:value) { page2 }
      it do
        is_expected.not_to include("column_value1")
        is_expected.to include("column_value2")
        is_expected.not_to include("column_value3")
      end
    end

    context "with page3" do
      let(:value) { page3 }
      it do
        is_expected.not_to include("column_value1")
        is_expected.not_to include("column_value2")
        is_expected.to include("column_value3")
      end
    end
  end

  describe "public_list" do
    let(:source) do
      templ = []
      templ << '{% assign pages = value | public_list %}'
      templ << '<div class="middle dw">'
      templ << '{% for page in pages %}'
      templ << '<div><h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2></div>'
      templ << '{% endfor %}'
      templ << '</div>'
      templ.join("\n")
    end

    context "with blank" do
      let(:value) { "" }
      it do
        is_expected.not_to include(page1.url)
        is_expected.not_to include(page2.url)
        is_expected.not_to include(page3.url)
      end
    end

    context "with node" do
      let(:value) { node.to_liquid }
      it do
        is_expected.to include(page1.url)
        is_expected.to include(page2.url)
        is_expected.to include(page3.url)
      end

      context 'with limit' do
        let(:source) do
          templ = []
          templ << '{% assign pages = value | public_list: 2 %}'
          templ << '<div class="middle dw">'
          templ << '{% for page in pages %}'
          templ << '<div><h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2></div>'
          templ << '{% endfor %}'
          templ << '</div>'
          templ.join("\n")
        end
        it do
          is_expected.to include(page1.url)
          is_expected.to include(page2.url)
          is_expected.not_to include(page3.url)
        end
      end
    end
  end

  describe "filter_by_column_value" do
    let(:source) do
      templ = []
      templ << '{% assign pages = value | filter_by_column_value: "column1.column_value1" %}'
      templ << '<div class="middle dw">'
      templ << '{% for page in pages %}'
      templ << '<div><h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2></div>'
      templ << '{% endfor %}'
      templ << '</div>'
      templ.join("\n")
    end

    context "with blank" do
      let(:value) { "" }
      it do
        is_expected.not_to include(page1.url)
        is_expected.not_to include(page2.url)
        is_expected.not_to include(page3.url)
      end
    end

    context "with page" do
      let(:value) { Article::Page.all.to_a }
      it do
        is_expected.to include(page1.url)
        is_expected.not_to include(page2.url)
        is_expected.not_to include(page3.url)
      end
    end
  end

  describe "sort_by_column_value" do
    let(:source) do
      templ = []
      templ << '{% assign pages = value | sort_by_column_value: "column1" %}'
      templ << '{% for page in pages %}'
      templ << '<p>{{ page.url }}</p>'
      templ << '{% endfor %}'
      templ.join
    end

    context "with blank" do
      let(:value) { "" }
      it do
        is_expected.not_to include("<p>#{page1.url}</p><p>#{page2.url}</p><p>#{page3.url}</p>")
      end
    end

    context "with pages" do
      let(:value) { Article::Page.all.to_a.reverse }
      it do
        is_expected.to include("<p>#{page1.url}</p><p>#{page2.url}</p><p>#{page3.url}</p>")
      end
    end
  end

  describe "same_name_pages" do
    let(:source) do
      templ = []
      templ << '{% assign pages = value | same_name_pages %}'
      templ << '<div class="middle dw">'
      templ << '{% for page in pages %}'
      templ << '<div><h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2></div>'
      templ << '{% endfor %}'
      templ << '</div>'
      templ.join("\n")
    end

    context "with blank" do
      let(:value) { "" }
      it do
        is_expected.not_to include(page1.url)
        is_expected.not_to include(page2.url)
        is_expected.not_to include(page3.url)
      end
    end

    context "with page" do
      let(:value) { page1.to_liquid }
      it do
        is_expected.not_to include(page1.url)
        is_expected.to include(page2.url)
        is_expected.to include(page3.url)
      end

      context 'with filename' do
        let(:source) do
          templ = []
          templ << "{% assign pages = value | same_name_pages: #{node.filename} %}"
          templ << '<div class="middle dw">'
          templ << '{% for page in pages %}'
          templ << '<div><h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2></div>'
          templ << '{% endfor %}'
          templ << '</div>'
          templ.join("\n")
        end
        it do
          is_expected.not_to include(page1.url)
          is_expected.to include(page2.url)
          is_expected.to include(page3.url)
        end
      end
    end
  end
end
