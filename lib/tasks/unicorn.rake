namespace :unicorn do
  desc "Start unicorn"
  task(start: :load_classes) { ::Tasks::Unicorn.start }

  desc "Stop unicorn"
  task(stop: :load_classes) { ::Tasks::Unicorn.stop }

  desc "Restart unicorn with USR2"
  task(restart: :load_classes) { ::Tasks::Unicorn.restart }

  desc "Increment number of worker processes"
  task(increment: :load_classes) { ::Tasks::Unicorn.increment }

  desc "Decrement number of worker processes"
  task(decrement: :load_classes) { ::Tasks::Unicorn.decrement }

  desc "Unicorn pstree (depends on pstree command)"
  task(pstree: :load_classes) { ::Tasks::Unicorn.pstree }

  task(:load_classes) do
    require_relative "./unicorn"
  end
end
