class Lsorg::GroupItem
  include SS::Liquidization

  attr_accessor :delegate_proc, :group, :name, :depth, :order, :basename, :node

  # relations

  def tree
    delegate_proc.call(self, :tree)
  end

  def tree_list
    tree.to_a
  end

  def root
    delegate_proc.call(self, :root)
  end

  def root?
    delegate_proc.call(self, :root?)
  end

  def full_name
    delegate_proc.call(self, :full_name)
  end

  def filename
    delegate_proc.call(self, :filename)
  end

  def parent
    delegate_proc.call(self, :parent)
  end

  def children
    delegate_proc.call(self, :children)
  end

  def descendants
    delegate_proc.call(self, :descendants)
  end

  # group

  delegate :overview, to: :group

  def contacts
    group.contact_groups
  end

  def main_contact
    contacts.where(main_state: "main").first
  end

  liquidize do
    # relations
    export :root
    export :root?
    export :parent
    export :children
    export :descendants
    export :tree_list

    # attr
    export :name
    export :full_name
    export :basename
    export :filename
    export :depth
    export :order
    export :group
    export :node

    # group
    export :overview
    export :contacts
    export :main_contact
  end
end
