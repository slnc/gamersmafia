require "test_helper"

class ApplicationControllerTest < ActiveSupport::TestCase

  def setup
    @controller = ApplicationController.new
    @controller.env = {}
  end

  def simulate_env(headers)
    headers.each do |k, v|
      @controller.env[k] = v
    end
  end

  test "should_return_ip_if_only_remote_addr" do
    self.simulate_env({"REMOTE_ADDR" => "127.0.0.1"})
    assert_equal "127.0.0.1", @controller.remote_ip
  end

  test "multiple_remote_addr_given_and_separated_with_comma_and_space" do
    self.simulate_env({"REMOTE_ADDR" => "217.127.6.140, 80.58.205.55"})
    assert_equal "217.127.6.140", @controller.remote_ip
  end

  test "multiple_remote_addr_given_and_separated_with_comma" do
    self.simulate_env({"REMOTE_ADDR" => "217.127.6.140,80.58.205.55"})
    assert_equal "217.127.6.140", @controller.remote_ip
  end

  test "multiple_remote_addr_given_and_separated_with_space" do
    self.simulate_env({"REMOTE_ADDR" => "217.127.6.140 80.58.205.55"})
    assert_equal "217.127.6.140", @controller.remote_ip
  end

  test "multiple_remote_addr_given_and_one_unknown_and_separated_with_space" do
    self.simulate_env({"REMOTE_ADDR" => "unknown, 84.125.101.75"})
    assert_equal "84.125.101.75", @controller.remote_ip
  end

  test "should_return_first_public_ip_if_one_private_address_given" do
    self.simulate_env({"REMOTE_ADDR" => "127.0.0.1, 84.125.101.75"})
    assert_equal "84.125.101.75", @controller.remote_ip
  end

  test "should_return_first_public_ip_if_one_private_address_given 2" do
    self.simulate_env({"REMOTE_ADDR" => "84.125.101.75 127.0.0.1"})
    assert_equal "84.125.101.75", @controller.remote_ip
  end

  test "should_return_first_private_ip_if_only_one_ip_given" do
    self.simulate_env({"REMOTE_ADDR" => "127.0.0.1"})
    assert_equal "127.0.0.1", @controller.remote_ip
  end

  test "should_return_first_private_ip_if_only_one_ip_given2" do
    self.simulate_env({"REMOTE_ADDR" => "192.168.0.1"})
    assert_equal "127.0.0.1", @controller.remote_ip
  end

  test "should_return_correct_ip_if_forwarded_for_unknown_unknown" do
    self.simulate_env({
        "REMOTE_ADDR" => "192.168.0.1",
        "HTTP_X_FORWARDED_FOR" => "unknown,unknown"})
    assert_equal "127.0.0.1", @controller.remote_ip
  end

  test "should_return_correct_ip_if_forwarded_for_known_known" do
    self.simulate_env({
        "REMOTE_ADDR" => "127.0.0.1",
        "HTTP_X_FORWARDED_FOR" => "88.20.248.67, 80.58.205.47"})
    assert_equal "88.20.248.67", @controller.remote_ip
  end

  test "should_return_correct_ip_if_forwarded_for_known" do
    self.simulate_env({
        "REMOTE_ADDR" => "127.0.0.1", "HTTP_X_FORWARDED_FOR" => "88.20.248.67"})
    assert_equal "88.20.248.67", @controller.remote_ip
  end
end
