require 'test_helper'

class CompetitionsLogsEntryTest < ActiveSupport::TestCase

  # TODO copypasted de competitions_logs_entry
  test "should_not_allow_empty_message" do
    log_entry = CompetitionsLogsEntry.new({:message => nil, :competition_id => 1})
    assert_equal false, log_entry.save
    assert_not_nil log_entry.errors[:message]

    log_entry = CompetitionsLogsEntry.new({:message => '', :competition_id => 1})
    assert_equal false, log_entry.save
    assert_not_nil log_entry.errors[:message]

    log_entry = CompetitionsLogsEntry.new({:message => nil, :competition_id => 1})
    assert_equal false, log_entry.save
    assert_not_nil log_entry.errors[:message]

    log_entry = CompetitionsLogsEntry.new({:message => ' ', :competition_id => 1})
    assert_equal false, log_entry.save
    assert_not_nil log_entry.errors[:message]
  end

  test "should_not_allow_empty_competition" do
    log_entry = CompetitionsLogsEntry.new({:message => 'foo'})
    assert_equal false, log_entry.save
    assert_not_nil log_entry.errors[:competition_id], log_entry.errors.full_messages.join(',')
  end

  test "should_sanitize_script_tags" do
    log_entry = CompetitionsLogsEntry.new({:message => 'aba<script type="text/javascript">alert(\'hello world\');"</script>aba', :competition_id => 1})
    assert_equal true, log_entry.save
    assert_equal 'aba&lt;script type="text/javascript"&gt;alert(\'hello world\');"&lt;/script&gt;aba', log_entry.message
  end

  test "should_truncate_really_long_messages" do
    @long_string = ''
    @cut_string = ''
    11.times { |i| @long_string << 'aaaaaaaaaa' }
    10.times { |i| @cut_string << 'aaaaaaaaaa' }
    log_entry = CompetitionsLogsEntry.new({:message => @long_string, :competition_id => 1})
    assert_equal true, log_entry.save
    assert_equal @cut_string, log_entry.message
  end

  test "should_allow_if_everything_correct" do
    now = Time.now
    log_entry = CompetitionsLogsEntry.new({:message => 'hola mundo', :competition_id => 1, :created_on => now})
    assert_equal true, log_entry.save
    assert_equal 'hola mundo', log_entry.message
    assert_equal 1, log_entry.competition_id
    assert_equal now, log_entry.created_on
  end

  test "should_be_modifiable" do
    assert_equal true, CompetitionsLogsEntry.find(:first).save
  end

  test "should_be_destroyable" do
    assert_equal true, CompetitionsLogsEntry.find(:first).destroy.frozen?
    assert_raises(ActiveRecord::RecordNotFound) { CompetitionsLogsEntry.find(1) }
  end
end
