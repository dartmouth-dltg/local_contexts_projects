
class LocalContextsProjectsRefreshCacheRunner < JobRunner

  # refreshing every project hits the Local Contexts API, so only let users who
  # can manage Local Contexts projects create these jobs
  register_for_job_type('local_contexts_projects_refresh_cache_job',
                        :create_permissions => :update_localcontexts_project_record)

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