
class LocalContextsProjectsRefreshCacheRunner < JobRunner

  register_for_job_type('local_contexts_projects_refresh_cache_job')

  def run

    begin
      @job.write_output("Refreshing Local Contexts cache for all Project Ids")
      lcp_client = LocalContextsClient.new
      lcp_client.check_or_reset_cache_multi(false)
      @job.write_output("Success refreshing Local Contexts cache for all projects")
      self.success!
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end

end