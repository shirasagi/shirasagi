class Rdf::PropertyExpander
  DEPTH_LIMIT = 5.freeze

  def initialize(depth_limit = DEPTH_LIMIT)
    @depth_limit = depth_limit
    @vocab_cache = {}
    @vocab_cache.default_proc = ->(hash, key) { set_vocab(hash, key) }
    @class_cache = {}
    @class_cache.default_proc = ->(hash, key) { set_class(hash, key) }
    @props_cache = {}
    @props_cache.default_proc = ->(hash, key) { set_class_props(hash, key) }
  end

  def with_vocab(vocab_id)
    yield @vocab_cache[vocab_id]
  end

  def with_class(class_id)
    yield @class_cache[class_id]
  end

  def with_props(class_id)
    yield @props_cache[class_id]
  end

  def expand(rdf_class, depth = 0, recuirsive_super_class_check = {})
    return [] if depth >= @depth_limit

    ret = expand_super_class_properties(rdf_class, depth, recuirsive_super_class_check)

    # check whether already flatterned.
    return ret if recuirsive_super_class_check.key?(rdf_class._id)
    recuirsive_super_class_check[rdf_class._id] = true

    properties = @props_cache[rdf_class._id]
    return ret if properties.blank?

    properties.each do |prop|
      prop_vocab = @vocab_cache[prop.vocab_id]
      range = @class_cache[prop.range_id]
      range_vocab = @vocab_cache[range.try(:vocab_id)]
      tmp = range.present? ? expand(range, depth + 1) : nil
      ret << [prop.id,
              "#{prop_vocab.prefix}:#{prop.name}",
              range.present? ? "#{range_vocab.prefix}:#{range.name}" : nil,
              prop.comments.try(:preferred_value),
              tmp]
    end

    ret
  end

  def flattern(rdf_class)
    properties = expand(rdf_class)
    return properties if properties.blank?
    flattern_properties_recursive(properties)
  end

  private
    def expand_super_class_properties(rdf_class, depth, recuirsive_super_class_check)
      return [] if rdf_class.sub_class.blank?

      rdf_class.sub_class.present? ? expand(rdf_class.sub_class, depth + 1, recuirsive_super_class_check) : []
    end

    def flattern_properties_recursive(roots)
      ret = []
      roots.each do |id, name, klass, comment, sub_props|
        if sub_props.present?
          flat_sub_props = flattern_properties_recursive(sub_props)
          flat_sub_props.each do |flat_sub_prop|
            flat_sub_prop[:ids].insert(0, id)
            flat_sub_prop[:names].insert(0, name.split(':')[1])
            flat_sub_prop[:properties].insert(0, name)
            flat_sub_prop[:classes].insert(0, klass)
            flat_sub_prop[:comments].insert(0, comment)
          end
          ret.concat(flat_sub_props)
        else
          ret << { ids: [id],
                   names: [name.split(':')[1]],
                   properties: [name],
                   classes: [klass],
                   comments: [comment]}
        end
      end
      ret
    end

    def set_vocab(hash, vocab_id)
      if vocab_id.present?
        hash[vocab_id] = ::Rdf::Vocab.where(_id: vocab_id).first
      end
    end

    def set_class(hash, class_id)
      if class_id.present?
        hash[class_id] = ::Rdf::Class.where(_id: class_id).first
      end
    end

    def set_class_props(hash, class_id)
      if class_id.present?
        rdf_class = @class_cache[class_id] if class_id.present?
        rdf_props = rdf_class.properties if rdf_class.present?
        rdf_props ||= []
        hash[class_id] = rdf_props.to_a if class_id.present?
      end
    end
end
