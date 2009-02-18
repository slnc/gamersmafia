class Admin::BjJobsController < AdministrationController
  
  def index
  end
  
  def job
    if params[:bj_job_id]
      @bjob = User.db_query("SELECT * FROM bj_job WHERE bj_job_id = #{params[:bj_job_id].to_i}")[0] 
    else
      @bjob = User.db_query("SELECT * FROM bj_job_archive WHERE bj_job_archive_id = #{params[:bj_job_archive_id].to_i}")[0]
    end
    raise ActiveRecord::RecordNotFound unless @bjob
  end
end
