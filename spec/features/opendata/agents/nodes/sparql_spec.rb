require 'spec_helper'

describe "opendata_agents_nodes_sparql", dbscope: :example do

  let(:node) { create_once :opendata_node_sparql, name: "opendata_sparql" }
  let(:index_path) { "#{node.url}" }

  let(:search_label) { "Run Query" }

  context "sparql" do

    it "#index" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit index_path
        expect(current_path).to eq index_path
      end
    end

    it "#html" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit index_path
        select "HTML", from: "format"
        click_button search_label

        visit index_path
        fill_in "query", with: "select distinct * where { graph ?g { ?s ?p 'TEST' . } } limit 100"
        select "HTML", from: "format"
        click_button search_label
      end
    end

    it "#html_table" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit index_path
        select "HTML (TABLE Only)", from: "format"
        click_button search_label

        visit index_path
        fill_in "query", with: "select distinct * where { graph ?g { ?s ?p 'TEST' . } } limit 100"
        select "HTML (TABLE Only)", from: "format"
        click_button search_label
      end
    end

    it "#json" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit index_path
        select "JSON", from: "format"
        click_button search_label
      end
    end

    it "#csv" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit index_path
        select "CSV", from: "format"
        click_button search_label
      end
    end

    it "#TSV" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit index_path
        select "TSV", from: "format"
        click_button search_label
      end
    end

    it "#XML" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", cms_site.domain)

        visit index_path
        select "XML", from: "format"
        click_button search_label
      end
    end

  end

end
