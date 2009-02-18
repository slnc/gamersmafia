require File.dirname(__FILE__) + '/../../test_helper'

class Admin::BjJobsControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :job ]
  
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_bj_job
    sym_login 1
    User.db_query("INSERT INTO bj_job(bj_job_id, command) VALUES(1, 'foo')")
    get :job, :bj_job_id => 1
    assert_response :success
    
    User.db_query("INSERT INTO bj_job_archive(bj_job_archive_id, command) VALUES(1, 'foo')")
    get :job, :bj_job_archive_id => 1
    assert_response :success
  end
end
