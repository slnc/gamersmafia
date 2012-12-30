# -*- encoding : utf-8 -*-
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test_unit_mixings.rb'
require 'test/unit'
require 'mocha/setup'

# lo metemos aquí porque test_helper parece que se incluye varias veces
class ActionController::TestRequest
  private
  def initialize_default_values
    # Copypasted por host
    @host                    = App.domain
    @fullpath             = "/"
    self.remote_addr         = "0.0.0.0"
    @env["SERVER_PORT"]      = 80
    @env['REQUEST_METHOD']   = "GET"
  end
end

class ActiveSupport::TestCase
  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true

  # Rails no incluye fixture_file_upload en esta clase. Quizás haya que
  # reescribir los tests para que no hagan uso de ello? No estoy seguro de que
  # sea incoherente de esta forma.
  #
  # https://rails.lighthouseapp.com/projects/8994/tickets/
  # 1985-fixture_file_upload-no-longer-available-in-tests-by-default
  def fixture_file_upload(path, mime_type = nil, binary = false)
    Rack::Test::UploadedFile.new("#{fixture_path}#{path}", mime_type, binary)
  end


  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false
  self.pre_loaded_fixtures = true

  #  @@fixtures_loaded = false
  #  def self.append_features(base)
  #    unless @@fixtures_loaded
  #      create_fixtures [:users] # array of all my tables
  #      @@fixtures_loaded = true
  #    end
  #  end

  def host_from_url(uri)
    URI::split(uri)[2]
  end

  def sym_pageview(opts)
    # req: url
    opts = {:ip => '127.0.0.1'}.merge(opts)
    User.db_query("INSERT INTO stats.pageviews(
                                               user_id,
                                               url,
                                               controller,
                                               action,
                                               model_id,
                                               ads_shown,
                                               ip)
                                   VALUES (
                                            #{opts[:user_id] ? opts[:user_id] : 'NULL'},
                                            '#{opts[:url]}',
                                            '#{opts[:controller] ? opts[:controller] : 'NULL'}',
                                            '#{opts[:action] ? opts[:action] : 'NULL'}',
                                            '#{opts[:model_id] ? opts[:model_id] : 'NULL'}',
                                            '#{opts[:ads_shown] ? opts[:ads_shown] : 'NULL'}',
                                            '#{opts[:ip]}'
                                            )")
  end

  def setup_faction_skin
    @s = FactionsSkin.create({:user_id => 1, :name => 'labeling'})
    assert !@s.new_record?
    assert @s.config[:general][:intelliskin]
    assert_not_nil @s.config[:intelliskin]
  end


  def self.test_min_acl_level(level, actions, method = :get)
    raise TypeError unless actions.kind_of?(Array)
    raise TypeError unless level.kind_of?(Symbol)
    @@min_acl_level = level
    @@min_acl_actions = actions

    def min_acl_level
      @@min_acl_level
    end

    def min_acl_actions
      @@min_acl_actions
    end

    actions.each do |action|
      define_method "test_min_acl_level_#{level}_#{action}" do
        @request.session[:user] = nil
        assert_raises(AccessDenied) { eval("#{method} action.to_sym") }

        case level
        when :superadmin
          assert_raises(AccessDenied) do
            eval("#{method} action.to_sym, {}, { :user => 2 }")
          end

          begin
            eval("#{method} action.to_sym, {}, { :user => 1 }")
          rescue AccessDenied
            raise
          rescue Exception
          end

        when :user
          begin
            eval("#{method} action.to_sym, {}, { :user => 2 }")
          rescue AccessDenied
            raise
          rescue Exception
          end

          begin
            eval("#{method} action.to_sym, {}, { :user => 1 }")
          rescue AccessDenied
            raise
          rescue Exception
          end
        else
          raise "#{level} unsupported"
        end
      end
    end
  end

  def sym_login(user_ident)
    case user_ident.class.name
      when 'User'
      @request.session[:user] = user_ident.id
      when 'Fixnum'
      @request.session[:user] = user_ident
      when 'String'
      @request.session[:user] = User.find_by_login(user_ident).id
      when 'Symbol'
      @request.session[:user] = User.find_by_login(user_ident.to_s).id
    else
      raise "#{user_ident.class.name} as user_ident unimplemented"
    end
    assert_not_nil session[:user]
  end

  def create_a_game
    @_create_a_game_idx ||= 0
    game = Game.new({
        :name => "Game#{@_create_a_game_idx}",
        :user_id => 1,
        :gaming_platform_id => 1,
    })
    assert game.save
    @_create_a_game_idx += 1
    game
  end

  def create_a_comment(opts={})
    final_opts = {
      :user_id => 2,
      :comment => "hola #{User.find(2).login}",
      :content_id => 1,
      :host => '127.0.0.1',
    }.merge(opts)
    Comment.create(final_opts)
  end

  def give_skill(user_id, role)
    if user_id.kind_of?(Fixnum)
      user = User.find(user_id)
    elsif user_id.kind_of?(String)
      user = User.find_by_login(user_id)
    elsif user_id.kind_of?(User)
      user = user_id
    end
    assert_difference("user.users_skills.count") do
      new_skill = user.users_skills.create(:role => role)
      puts new_skill.errors.full_messages_html if new_skill.new_record?
    end
  end

  def buy_product(user, product_class)
    product_class.create({
        :user_id => user.id,
        :product_id => Product.find_by_cls(product_class.name).id,
        :price_paid => 1,
    })
  end

  def remove_skill(user_id, role)
    if user_id.kind_of?(Fixnum)
      user = User.find(user_id)
    elsif user_id.kind_of?(String)
      user = User.find_by_login(user_id)
    end

    assert_difference("user.users_skills.count", -1) do
      user.users_skills.find_by_role(role).destroy
    end
  end

  def post_comment_on(content)
    assert request.session[:user]
    c_text = (Kernel.rand * 100000).to_s
    comments_count = Comment.count
    post '/comments/create', { :comment => { :comment => c_text,
                                             :content_id => content.id } }
    assert_response :redirect, @response.body
    assert_equal comments_count + 1, Comment.count
    last_c = content.comments.find(:first, :conditions => "deleted = 'f'",
                                                  :order => 'id DESC')
    assert_not_nil last_c
    assert_equal c_text, last_c.comment
  end

  def post_comment_on_unittest(content,
                               options = { :comment => "#{Kernel.rand(1000)}Hola mundo!",
                                           :user_id => 1,
                                           :host => '127.0.0.1' })
    content_id = (content.class.name == 'Content') ? content.id :
                                                     content.id

    content = Comment.new(options.merge({:content_id => content_id}))
    assert_equal true, content.save
    content
  end

  def go_to(url, template=nil)
    get url
    assert_response :success, response.body
    if template.nil?
      assert_template url[1..-1] # quitamos el /
    else
      assert_template template
    end
  end

  def delete_content(content)
    assert content.state != Cms::DELETED
    content.update_attribute(:state, Cms::DELETED)
    content.reload
    assert_equal Cms::DELETED, content.state
  end

  def rate_content(content)
    prev = ContentRating.count
    post '/site/rate_content', { :content_rating => { :content_id => content.id, :rating => '5'} }
    assert_response :success
    assert_equal prev + 1, ContentRating.count
  end

  def publish_content(content)
    assert content.state != Cms::PUBLISHED
    Content.publish_content_directly(content, User.find(1))
    content.reload
    assert_equal Cms::PUBLISHED, content.state
  end

  def self.fixtures(*a)
  end

  def file_hash(somefile)
    md5_hash = ''
    assert_equal true, File.exists?(somefile), "#{somefile} doesn't exists"
    File.open(somefile) do |f| # binmode es vital por los saltos de línea y win/linux
      f.binmode
      md5_hash = Digest::MD5.hexdigest(f.read)
    end
    md5_hash
  end
end

class ActionController::IntegrationTest
  def setup
        host! App.domain
  end

  def sym_login(login, pass)
    logout if (request && request.session && request.session[:user])
    post '/cuenta/do_login', { :login => login, :password => pass }
    assert_response :redirect, @response.body
    assert_not_nil request.session[:user]
  end

  def logout
    if request.session[:user]
      post '/cuenta/logout'
      assert_response :redirect
      assert_nil request.session[:user]
    end
  end

  def create_content(type, content_vals, other_vals={})
    cls_name = ActiveSupport::Inflector::camelize(type.to_s)
    action = (cls_name == 'Topic') ? 'create_topic' : 'create'
    ocount = Object.const_get(cls_name).count
    post "/#{Cms::CONTENTS_CONTROLLERS.fetch(cls_name)}/#{action}", other_vals.merge({ type.to_sym => content_vals })
    assert_response :redirect, @response.body
    assert_equal ocount + 1, Object.const_get(cls_name).count
  end
end

class ActiveSupport::TestCase
  def self.basic_test(*views)
    cattr_accessor :basic_views_test
    self.basic_views_test = views

    class_eval <<-END
      test "basic_views" do
        self.basic_views_test.each do |view|
          get view
          assert_response :success
        end
      end
    END
  end
end
