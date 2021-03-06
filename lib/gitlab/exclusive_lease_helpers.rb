module Gitlab
  # This module provides helper methods which are intregrated with GitLab::ExclusiveLease
  module ExclusiveLeaseHelpers
    FailedToObtainLockError = Class.new(StandardError)

    ##
    # This helper method blocks a process/thread until the other process cancel the obrainted lease key.
    #
    # Note: It's basically discouraged to use this method in the unicorn's thread,
    #       because it holds the connection until all `retries` is consumed.
    #       This could potentially eat up all connection pools.
    def in_lock(key, ttl: 1.minute, retries: 10, sleep_sec: 0.01.seconds)
      lease = Gitlab::ExclusiveLease.new(key, timeout: ttl)

      until uuid = lease.try_obtain
        # Keep trying until we obtain the lease. To prevent hammering Redis too
        # much we'll wait for a bit.
        sleep(sleep_sec)
        break if (retries -= 1) < 0
      end

      raise FailedToObtainLockError, 'Failed to obtain a lock' unless uuid

      return yield
    ensure
      Gitlab::ExclusiveLease.cancel(key, uuid)
    end
  end
end
