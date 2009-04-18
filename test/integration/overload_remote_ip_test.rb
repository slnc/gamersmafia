require 'test_helper'


class OverloadRemoteIpTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end
  
  def atest_should_return_ip_if_only_remote_addr
    get '/'
    assert_equal '127.0.0.1', @request.remote_ip
  end
  
  def atest_should_return_first_public_ip_if_multiple_remote_addr_given_and_separated_with_comma_and_space
    get '/', {}, { :REMOTE_ADDR => '217.127.6.140, 80.58.205.55' }
    assert_equal '217.127.6.140', @request.remote_ip
  end
  
  def atest_should_return_first_public_ip_if_multiple_remote_addr_given_and_separated_with_comma
    get '/', {}, { :REMOTE_ADDR => '217.127.6.140,80.58.205.55' }
    assert_equal '217.127.6.140', @request.remote_ip
  end
  
  def atest_should_return_first_public_ip_if_multiple_remote_addr_given_and_separated_with_space
    get '/', {}, { :REMOTE_ADDR => '217.127.6.140 80.58.205.55' }
    assert_equal '217.127.6.140', @request.remote_ip
  end
  
  def atest_should_return_first_public_ip_if_multiple_remote_addr_given_and_one_is_unknown_and_separated_with_space
    get '/', {}, { :REMOTE_ADDR => 'unknown, 84.125.101.75' }
    assert_equal '84.125.101.75', @request.remote_ip
  end
  
  def atest_should_return_first_public_ip_if_one_private_address_given
    get '/', {}, { :REMOTE_ADDR => '127.0.0.1, 84.125.101.75' }
    assert_equal '84.125.101.75', @request.remote_ip
  end
  
  def atest_should_return_first_public_ip_if_one_private_address_given
    get '/', {}, { :REMOTE_ADDR => '84.125.101.75 127.0.0.1' }
    assert_equal '84.125.101.75', @request.remote_ip
  end
  
  def atest_should_return_first_private_ip_if_only_one_ip_given
    get '/', {}, { :REMOTE_ADDR => '127.0.0.1' }
    assert_equal '127.0.0.1', @request.remote_ip
  end
  
  def atest_should_return_first_private_ip_if_only_one_ip_given2
    get '/', {}, { :REMOTE_ADDR => '192.168.0.1' }
    assert_equal '192.168.0.1', @request.remote_ip
  end
  
  def atest_should_return_correct_ip_if_forwarded_for_unknown_unknown
    get '/', {}, { :REMOTE_ADDR => '192.168.0.1', :HTTP_X_FORWARDED_FOR => 'unknown,unknown' }
    assert_equal '192.168.0.1', @request.remote_ip    
  end
  
  test "should_return_correct_ip_if_forwarded_for_known_known" do
    get '/', {}, { :REMOTE_ADDR => '127.0.0.1', :HTTP_X_FORWARDED_FOR => '88.20.248.67, 80.58.205.47' }
    assert_equal '80.58.205.47', @request.remote_ip
  end
  
  test "should_return_correct_ip_if_forwarded_for_known" do
    get '/', {}, { :REMOTE_ADDR => '127.0.0.1', :HTTP_X_FORWARDED_FOR => '88.20.248.67' }
    assert_equal '88.20.248.67', @request.remote_ip
  end
end
