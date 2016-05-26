class Ldap::SyncTask
  include SS::Model::Task
  include SS::Reference::Site

  default_scope ->{ where(name: "ldap::sync") }

  field :results, type: Hash
end
