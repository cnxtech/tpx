module TPX
  class Prom
    def initialize(exec)
      @cnt = 0
      @exec = exec
      @q = exec.schedule_m_build
    end

    def add(args, &block)
      @exec.schedule_m_add([@q, @cnt, args], &block)
      @cnt += 1
    end

    def resolve
      @exec.schedule_m_read(@q, @cnt)
    end
  end

  class Exec

    def initialize(size, opts = {})
      tix = opts[:tix]

      @size = size
      @jobs = Queue.new

      @pool = Array.new(size) do
        Thread.new do
          Thread.current[:tix] = tix if tix
          catch(:exit) do
            loop do
              begin
                jix, job, args, acc = @jobs.pop
                acc << [jix, job.call(*args)]
              rescue => e
                acc << 'ERROR'
              end
            end
          end
        end
      end
    end

    def schedule(args, &block)
      acc = Queue.new
      @jobs << [0, block, args, acc]
      (acc.pop)[1]
    end

    def schedule_m_build
      Queue.new
    end

    def schedule_m_add(args, &block)
      acc = args[0]
      jix = args[1]
      args = args[2]
      @jobs << [jix, block, args, acc]
    end

    def schedule_m_read(acc, n)
      res = []

      while res.size < n do
        res << (acc.pop)
      end

      res
    end

    def shutdown
      @size.times do
        schedule { throw :exit }
      end

      @pool.map(&:join)
    end
  end
end
