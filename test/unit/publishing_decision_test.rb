require 'test_helper'

class PublishingDecisionTest < ActiveSupport::TestCase
  FIRST_CONTENT_EXP = 0.00009655
  
  def setup
    @panzer = User.find_by_login(:panzer)
    @superadmin = User.find_by_login(:superadmin)
    @superadmin2 = User.find_by_login(:superadmin2)
    @mrman = User.find_by_login(:MrMan)
    @panzer_personality = PublishingPersonality.find_or_create(@panzer, ContentType.find_by_name('News'))
  end
  
  def make_a_decision(decision, user, deny_reason=nil, content=nil)
    if @n.nil? and content.nil?
      @n = News.find(:first, :conditions => 'clan_id is null and state = 1', :order => 'id DESC')
    elsif !content.nil?
      @n = content
    end
    
    assert %w(publish_content deny_content destroy_content).include?(decision.to_s)
    b_decision = (decision.to_s == 'publish_content')
    # n = News.find(:first, :conditions => 'state = 1', :order => 'id DESC')
    assert_not_nil @n
    if decision == :deny_content
      Cms.deny_content(@n, user, deny_reason)
    elsif decision == :destroy_content
      Cms.modify_content_state(@n, user, Cms::DELETED, deny_reason)
    else
      Cms.publish_content(@n, user)
    end
    if %w(publish_content deny_content).include?(decision.to_s)
      assert_not_nil PublishingDecision.find(:first, :conditions => ['user_id = ? and content_id = ? and publish = ?', user.id, @n.unique_content.id, b_decision])
    end
  end
  
  # crea suficientes_publishing_decisions como para que alcance el maximo de
  # poder de publicacion (0.99)
  def maximize_exp(user)
    raise 'MrMan no puede ser el user a maximizar' if user.login == 'MrMan'
    personality = PublishingPersonality.find_or_create(user, ContentType.find_by_name('News'))
    # creamos 20 noticias y las publicamos
     (Cms::min_hits_before_reaching_max_publishing_power('News') + 1).times do |i|
      n = News.create({:title => "maximize_exp#{i}", :description => 'foo', :terms => 1, :user_id => @mrman.id})
      assert_not_nil n
      Cms.publish_content(n, user)
      Cms.publish_content(n, @superadmin)
    end
    personality.reload
    assert_in_delta 0.99, personality.experience, 0.001
  end
  
  # reject: cuando un usuario vota que un contenido no se publique
  # accept: cuando un usuario vota que un contenido se publique
  test "users_exp_doesnt_change_when_he_accepts_a_content" do
    exp = @panzer_personality.experience
    make_a_decision :publish_content, @panzer
    @panzer_personality.reload
    assert_in_delta 0.00, @panzer_personality.experience, 0.001
  end
  
  test "users_exp_doesnt_change_when_he_denies_a_content" do
    exp = @panzer_personality.experience
    make_a_decision :deny_content, @panzer, 'feo'
    @panzer_personality.reload
    assert_in_delta 0.00, @panzer_personality.experience, 0.001
  end
  
  test "users_exp_increases_when_a_content_he_accepted_is_published" do
    exp = @panzer_personality.experience
    assert_equal 0.0, exp
    make_a_decision :publish_content, @panzer
    make_a_decision :publish_content, @superadmin
    @panzer_personality.reload
    assert_in_delta FIRST_CONTENT_EXP, @panzer_personality.experience, 0.00001
  end
  
  test "users_exp_increases_when_a_content_he_denied_and_became_denied_changes_and_now_is_published" do
    exp = @panzer_personality.experience
    assert_equal 0.0, exp
    make_a_decision :deny_content, @panzer
    pd = @panzer.publishing_decisions.find(:first, :order => 'created_on DESC')
    assert_not_nil pd
    make_a_decision :deny_content, @superadmin # make sure the content is denied
    pd.reload
    assert_equal true, pd.is_right
    # now change the user's decision and then the publishing decision
    make_a_decision :publish_content, @superadmin
    pd.reload
    assert_equal false, pd.is_right
    @panzer_personality.reload
    assert_equal 0.0, @panzer_personality.experience
    # assert_in_delta (-1)*((2.0 / Cms::min_hits_before_reaching_max_publishing_power('News')) ** Math::E), @panzer_personality.experience, 0.00001
    make_a_decision :publish_content, @panzer
    pd.reload
    assert_equal true, pd.is_right
    @panzer_personality.reload
    assert_in_delta FIRST_CONTENT_EXP, @panzer_personality.experience, 0.00001
  end
  
  # Solo sabemos si se ha publicado incorrectamente si un editor cambia el
  # estado del contenido de 2 a 3 o viceversa
  test "users_exp_decreases_when_a_content_he_accepted_is_denied" do
    exp = @panzer_personality.experience
    assert_equal 0.0, exp
    make_a_decision :publish_content, @panzer
    make_a_decision :deny_content, @superadmin, 'feo'
    @panzer_personality.reload
    assert_equal 0.0, @panzer_personality.experience
    # assert_in_delta (-1)*((2.0 / Cms::min_hits_before_reaching_max_publishing_power('News')) ** Math::E), @panzer_personality.experience, 0.00001
  end
  
  test "users_exp_decreases_when_a_content_he_accepted_is_deleted" do
    exp = @panzer_personality.experience
    assert_equal 0.0, exp
    make_a_decision :publish_content, @panzer
    make_a_decision :publish_content, @superadmin, 'feo'
    make_a_decision :destroy_content, @superadmin, 'feo'
    @panzer_personality.reload
    assert_equal 0.0, @panzer_personality.experience
    # assert_in_delta (-1)*((2.0 / Cms::min_hits_before_reaching_max_publishing_power('News')) ** Math::E), @panzer_personality.experience, 0.00001
  end
  
  test "users_exp_increases_when_a_content_he_rejected_is_denied" do
    exp = @panzer_personality.experience
    assert_equal 0.0, exp
    make_a_decision :deny_content, @panzer, 'feo'
    make_a_decision :deny_content, @superadmin, 'feo'
    @panzer_personality.reload
    assert_in_delta FIRST_CONTENT_EXP, @panzer_personality.experience, 0.00001
  end
  
  test "users_exp_decreases_when_a_content_he_rejected_is_published" do
    exp = @panzer_personality.experience
    assert_equal 0.0, exp
    make_a_decision :deny_content, @panzer, 'feo'
    make_a_decision :publish_content, @superadmin
    @panzer_personality.reload
    assert_equal 0.0, @panzer_personality.experience
    # assert_in_delta (-1)*((2.0 / Cms::min_hits_before_reaching_max_publishing_power('News')) ** Math::E), @panzer_personality.experience, 0.00001
  end
  
  test "faction_boss_user_can_publish_directly" do
    n = News.find(:first, :conditions => 'clan_id is null and state = 1', :order => 'id DESC')
    n.created_on = 1.week.ago
    n.save
    f = Organizations.find_by_content(n)
    assert_not_nil f
    f.update_boss(@panzer) if !f.is_bigboss?(@panzer)
    make_a_decision :publish_content, @panzer
    n.reload
    assert_equal Cms::PUBLISHED, n.state
  end
  
  test "power_user_can_publish_directly" do
    n = News.find(:first, :conditions => 'clan_id is null and state = 1', :order => 'id DESC')
    make_a_decision :publish_content, @superadmin
    n.reload
    assert_equal Cms::PUBLISHED, n.state
  end
  
  test "power_user_can_deny_directly" do
    n = News.find(:first, :conditions => 'clan_id is null and state = 1', :order => 'id DESC')
    make_a_decision :deny_content, @superadmin, 'feo'
    n.reload
    assert_equal Cms::DELETED, n.state
  end
  
  test "multiple_users_can_manage_to_publish_a_content_if_reaches_1_0" do
    test_users_exp_increases_when_a_content_he_accepted_is_published
    @mralariko = User.find_by_login('mralariko')
    assert_not_nil @mralariko
    maximize_exp(@mralariko)
    
    6.times do |t|
      n = News.create({:title => "maximize_exp#{t}", :description => 'foo', :terms => 1, :user_id => @mrman.id, :state => 1})
      assert_not_nil n
      Cms.publish_content(n, @superadmin)
      Cms.publish_content(n, @panzer)
    end
    
    n = News.create({:title => "maximize_exp2", :description => 'foo', :terms => 1, :user_id => @mrman.id, :state => 1})
    assert_not_nil n
    Cms.publish_content(n, @mralariko)
    Cms.publish_content(n, @panzer)
    assert_equal Cms::PUBLISHED, n.state
  end
  
  test "multiple_users_can_manage_to_deny_a_content_if_reaches_minus_1_0" do
    test_users_exp_increases_when_a_content_he_accepted_is_published
    @mralariko = User.find_by_login('mralariko')
    assert_not_nil @mralariko
    maximize_exp(@mralariko)
    
    6.times do |t|
      n = News.create({:title => "maximize_exp#{t}", :description => 'foo', :terms => 1, :user_id => @mrman.id, :state => 1})
      assert_not_nil n
      Cms.publish_content(n, @superadmin)
      Cms.publish_content(n, @panzer)
    end
    
    @n = News.create({:title => "maximize_exp2", :description => 'foo', :terms => 1, :user_id => @mrman.id, :state => 1})
    assert_not_nil @n
    Cms.deny_content(@n, @mralariko, 'feo')
    Cms.deny_content(@n, @panzer, 'feo')
    assert_equal Cms::DELETED, @n.state
  end
  
  test "users_faith_increases_when_making_a_publishing_decision" do
    initial_faith = @panzer.faith_points
    @n = News.find(:first, :conditions => 'state = 1')
    Cms.publish_content(@n, @panzer)
    @panzer.reload
    assert_equal initial_faith + Faith::FPS_ACTIONS['publishing_decision'], @panzer.faith_points
  end
  
  test "users_faith_points_doesnt_increase_with_incorrect_publishing_decisions" do
    test_users_faith_increases_when_making_a_publishing_decision
    initial_faith = @panzer.faith_points
    make_a_decision :deny_content, @superadmin, 'feo'
    @panzer.reload
    assert_equal initial_faith - Faith::FPS_ACTIONS['publishing_decision'], @panzer.faith_points
  end
  
  # 0 aciertos => 0.00
  # 1 acierto  => 0.01
  # 20 aciertos => 0.99
  # etc
  # (((aciertos - fallos) / min_aciertos_para_max_peso) ** Math::E)
  test "users_exp_behaves_as_expected_exp_function_while_hits_and_misses_are_modified" do
  end
  
  test "last_editor_must_overturn_any_previous_publishing_decision" do
    test_multiple_users_can_manage_to_deny_a_content_if_reaches_minus_1_0
    User.db_query("UPDATE publishing_personalities set experience = 1.0")
    Cms.deny_content(@n, @superadmin2, 'fff')
    @n.reload
    assert_equal Cms::DELETED, @n.state
    Cms.publish_content(@n, @superadmin)
    @n.reload
    assert_equal Cms::PUBLISHED, @n.state
  end
  
  test "non_editor_cant_vote_on_his_content" do
    n = News.create({:title => "check_exp_non_editor", :description => 'foo', :terms => 1, :user_id => @panzer.id, :state => Cms::PENDING})
    assert_not_nil n
    assert_equal Cms::PENDING, n.state
    assert_raises(AccessDenied) { Cms::publish_content(n, @panzer) }
    assert_raises(AccessDenied) { Cms::deny_content(n, @panzer, 'foo') }
  end
  
  # TODO faltan tests para cuando se modifica una decisión
end
