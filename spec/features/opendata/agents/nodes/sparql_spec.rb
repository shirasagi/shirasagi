require 'spec_helper'

describe "opendata_agents_nodes_sparql", dbscope: :example do

  let(:node) { create_once :opendata_node_sparql, name: "opendata_sparql" }
  let(:index_path) { node.url }

  let(:search_label) { "Run Query" }

  context "sparql is disabled" do
    before do
      @save_config = SS.config.opendata.fuseki
      SS.config.replace_value_at(:opendata, :fuseki, { "disable" => true })
    end

    after do
      SS.config.replace_value_at(:opendata, :fuseki, @save_config)
    end

    describe "search" do
      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          expect(current_path).to eq index_path

          select "HTML", from: "format"
          click_button search_label

          expect(page).to have_content("Disabled")
        end
      end
    end
  end

  context "sparql is enabled" do
    before do
      @save_config = SS.config.opendata.fuseki
      SS.config.replace_value_at(:opendata, :fuseki, { "disable" => false })
    end

    after do
      SS.config.replace_value_at(:opendata, :fuseki, @save_config)
    end

    describe "search and get html with no data" do
      let(:data) { "" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "text/html", data: data })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "HTML", from: "format"
          click_button search_label

          expect(page).to have_content("No Data")
        end
      end
    end

    describe "search and get html with valid result" do
      let(:data) { "<table class=\"sparql\"><tr><td>spec</td></tr></table>" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "text/html", data: data })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "HTML", from: "format"
          click_button search_label

          expect(page).to have_content("spec")
        end
      end
    end

    describe "search and get html_table with no data" do
      let(:data) { "" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "text/html", data: data })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "HTML (TABLE Only)", from: "format"
          click_button search_label

          expect(page).to have_content("No Data")
        end
      end
    end

    describe "search and get html_table with valid data" do
      let(:data) { "<table class=\"sparql\"><tr><td>spec</td></tr></table>" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "text/html", data: data })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "HTML (TABLE Only)", from: "format"
          click_button search_label

          expect(page).to have_content("spec")
        end
      end
    end

    describe "search and get json" do
      let(:data) { "{ \"key\": \"spec\" }" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "application/json", data: data, ext: "json" })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "JSON", from: "format"
          click_button search_label

          expect(page).to have_content("spec")
        end
      end
    end

    describe "#csv" do
      let(:data) { "A,B,C" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "text/csv", data: data, ext: "csv" })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "CSV", from: "format"
          click_button search_label

          expect(page).to have_content("A,B,C")
        end
      end
    end

    describe "#TSV" do
      let(:data) { "A\tB\tC" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "text/plain", data: data, ext: "txt" })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "TSV", from: "format"
          click_button search_label

          expect(page).to have_content("A\tB\tC")
        end
      end
    end

    describe "#XML" do
      let(:data) { "<a>spec</a>" }

      before do
        allow(Opendata::Sparql).to receive(:select).and_return({ type: "application/xml", data: data, ext: "xml" })
      end

      it do
        page.driver.browser.with_session("public") do |session|
          session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

          visit index_path
          select "XML", from: "format"
          click_button search_label

          expect(page).to have_content("spec")
        end
      end
    end
  end
end
