require 'spec_helper'

describe Ldap::Import do
  subject(:model) { Ldap::Import }
  subject(:factory) { :ldap_import }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
