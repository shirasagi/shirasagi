class SS::Group
  include SS::Model::Group
  include SS::Liquidization

  liquidize do
    export :name
    export :full_name
    export :section_name
    export :trailing_name
    export :last_name do
      name.split("/").last
    end
  end
end
