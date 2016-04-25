def can_test_open_jtalk_spec?
  # be carefule, open jtalk spec is slow.
  # you will waste a lot of time if you turn on allow_open_jtalk.
  return false if ENV["allow_open_jtalk"].to_i == 0
  return false if SS.config.voice.disable
  unless ::File.exists?(SS.config.voice['openjtalk']['bin'])
    puts("[Open JTalk Spec] not found: #{SS.config.voice['openjtalk']['bin']}")
    return false
  end
  unless ::Dir.exists?(SS.config.voice['openjtalk']['dic'])
    puts("[Open JTalk Spec] not found: #{SS.config.voice['openjtalk']['dic']}")
    return false
  end
  unless ::File.exists?(SS.config.voice['openjtalk']['sox'])
    puts("[Open JTalk Spec] not found: #{SS.config.voice['openjtalk']['sox']}")
    return false
  end
  unless ::File.exists?(SS.config.voice['lame']['bin'])
    puts("[Open JTalk Spec] not found: #{SS.config.voice['lame']['bin']}")
    return false
  end
  true
end

RSpec.configuration.after(:suite) do
  ::FileUtils.rm_rf Voice::File.root if ::Dir.exists?(Voice::File.root)
end

RSpec.configuration.filter_run_excluding(open_jtalk: true) unless can_test_open_jtalk_spec?
