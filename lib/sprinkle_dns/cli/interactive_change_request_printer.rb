module SprinkleDNS::CLI
  class InteractiveChangeRequestPrinter
    def initialize
      @redraws = 0
    end

    def draw(change_requests)
      lines = []

      change_requests.each do |change_request|
        dots   = '.' * change_request.tries
        sync   = change_request.in_sync ? '✔' : '✘'
        status = change_request.in_sync ? 'PROPAGATED' : 'PROPAGATING'
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
