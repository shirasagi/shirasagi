namespace :ss do
  task :models => :environment do
    models = {}
    fields = {}

    Mongoid.models.each do |model|
      next if model.to_s =~ /^Mongoid::/

      coll = model.collection_name
      coll_t = I18n.t "mongoid.models.#{model.to_s.underscore}"
      models[coll] ||= coll_t if coll_t !~ /[\.:\/]/
      fields[coll] ||= {}

      model.fields.each do |name, field|
        next if fields[coll][name].present?

        if name == "_id"
          name_t = "ID"
        else
          name_t = model.t name
          name_t = nil if name_t =~ /[\.:\/]/
        end

        type = field.type.to_s
        meta = nil

        #if type == "SS::Extensions::ObjectIds"
          #type = "Array"
          #meta = "##{field.metadata[:elem_class]}" if field.metadata[:elem_class]
        #elsif type == "Object" && name =~ /_id$/
          #type = "Integer"
          #meta = "##{field.metadata[:class_name]}" if field.metadata[:class_name]
        #elsif type == "SS::Extensions::Words"
          #type = "Array"
          #meta = "Words"
        #end

        fields[coll][name] = "#{type}\t#{name_t}\t#{meta}"
      end
    end

    tsv = ""
    tsv << "Collection\tField\tType\tMemo\n"
    fields.sort.each do |coll, coll_data|
      coll_t = models[coll]

      idx = 0
      coll_data.each do |name, val|
        if idx == 0
          tsv << "#{coll}\t"
        elsif idx == 1
          tsv << "#{coll_t}\t"
        else
          tsv << "\t"
        end
        idx += 1

        tsv << "#{name}\t#{val}\n"
      end
    end

    output = "#{Rails.root}/tmp/models.txt"
    File.write(output, tsv)

    puts tsv
    puts ">> #{output}"
  end
end
