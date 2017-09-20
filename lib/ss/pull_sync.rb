class SS::PullSync
  def initialize(model)
    @model = model
    @client_name = model.client_name
    @collection_name = model.collection_name
    @public_clients = Mongoid::Config.clients.select { |name, client| name =~ /^public(_|$)/ }
  end

  def pull_all_and_delete
    puts "--- Pull and Delete ---"

    @public_clients.each do |client_name, client|
      db = client[:database]
      coll = Mongoid::Clients.with_name(client_name).use(db)[@collection_name]

      puts "# #{client_name}/#{db}.#{@collection_name}"

      coll.find({}, { projection: { _id: 1 }}).each do |pull_id|
        pull_id = pull_id[:_id]
        pull_data = coll.find({ _id: pull_id }).first
        pull_data.delete(:_id)

        item = @model.new(pull_data)
        if !item.save
          puts msg = "[#{pull_id}] save error: " + item.errors.full_messages.join(' ')
          Rails.logger.error(msg)
          next
        end

        result = coll.delete_one({ _id: pull_id })
        if result.deleted_count == 0
          puts msg = "[#{pull_id}] could not be deleted."
          Rails.logger.error(msg)
          next
        end

        puts "[#{pull_id}] success."
      end
    end
  end
end
