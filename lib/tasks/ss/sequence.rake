namespace :ss do
  task remove_minutely_sequence: :environment do
    puts "delete minutely sequences"
    today = Time.zone.now.strftime('%Y%m%d0000')

    SS::Sequence.where(id: /\Aminutely_/).each do |item|
      time = item.id.to_s.sub(/\Aminutely_(\d+)_.*/, '\\1')
      next if time.to_i >= today.to_i

      item.destroy
    end
  end

  task reset_sequence: :environment do
    ::Rails.application.eager_load!

    model = ENV["model"]
    model = model.constantize if model.present?

    if model.present?
      SS::Sequence.where(id: /#{model.collection_name}/).destroy_all
      models = [model]
    else
      SS::Sequence.destroy_all
      models = ::Mongoid.models
    end

    models.each do |model|
      puts "collection: #{model.collection_name}"
      sequenced_fields = model.try(:sequenced_fields) || []
      sequenced_fields.each do |key|
        field = (key == :id) ? :_id : key
        sid = "#{model.collection_name}_#{key}"
        doc = SS::Sequence.collection.database[model.collection_name].find.sort(field => -1).first
        sequence = SS::Sequence.find_by(_id: sid) rescue nil
        unless doc
          if sequence
            puts "  #{key}: delete sequence"
            sequence.destroy
          end
          next
        end

        val = doc[field].to_i

        if sequence
          next if sequence.value == val
          puts "  #{key}: actual=#{sequence.value} expected=#{val}"
          sequence.value = val
        else
          puts "  #{key}: creating new sequence with #{val}"
          sequence = SS::Sequence.new(_id: sid, value: val)
        end
        sequence.save!
      end
    end
  end
end
