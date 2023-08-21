require 'spec_helper'

describe Cms::Site, type: :model, dbscope: :example do
  let!(:site) { cms_site }

  context "basic usage" do
    it do
      site.syntax_checker_url_scheme_attributes = %w(href src data-ref)
      site.syntax_checker_url_scheme_schemes = %w(http https tel mailto)
      site.save!

      expect(site.syntax_checker_url_scheme_attributes).to eq %w(href src data-ref)
      expect(site.syntax_checker_url_scheme_schemes).to eq %w(http https tel mailto)
    end
  end

  context "scheme ends with colon(:)" do
    it do
      site.syntax_checker_url_scheme_schemes = %w(http: https: tel: mailto:)
      site.save!

      expect(site.syntax_checker_url_scheme_schemes).to eq %w(http https tel mailto)
    end
  end
end
