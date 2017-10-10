require 'spec_helper'

describe "gws_faq_topics", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_faq_topics_path site }
end
