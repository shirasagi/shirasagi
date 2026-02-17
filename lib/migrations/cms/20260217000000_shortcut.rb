class SS::Migration20260217000000
  include SS::Migration::Base

  depends_on "20251023000000"

  def change
    Cms::Node.all.then do |criteria|
      criteria = criteria.where(shortcut: "show")
      criteria = criteria.where(shortcuts: { "$exists" => false })
      criteria.set(shortcuts: [ Cms::Node::SHORTCUT_SYSTEM, Cms::Node::SHORTCUT_QUOTA ])
    end

    Cms::Node.all.then do |criteria|
      criteria = criteria.where(shortcut: { "$exists" => true })
      criteria.unset(:shortcut)
    end
  end
end
