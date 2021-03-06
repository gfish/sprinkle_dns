module SprinkleDNS::CLI
  class InteractiveChangeRequestPrinter
    def initialize
      reset!
    end

    def reset!
      @redraws = 0
    end

    def draw(change_requests, sync_word = "SYNCING", synced_word = "SYNCED")
      lines = []

      change_requests.each do |change_request|
        dots   = '.' * change_request.tries
        sync   = change_request.in_sync ? '✔' : '✘'
        status = change_request.in_sync ? synced_word : sync_word
        lines << "#{sync} #{status} #{change_request.hosted_zone.name}#{dots}"
      end

      if @redraws > 0
        clear = "\r" + ("\e[A\e[K") * lines.size
        puts clear + lines.join("\n")
      else
        puts lines.join("\n")
      end

      @redraws += 1
      sleep(2)
    end
  end
end
