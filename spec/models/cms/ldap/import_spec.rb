require 'spec_helper'

describe Cms::Ldap::Import do
  subject(:model) { Cms::Ldap::Import }
  subject(:factory) { :ldap_import }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
