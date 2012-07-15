# -*- encoding : utf-8 -*-
require 'test/unit'

module Test::Unit::Assertions

  def overload_rake_for_tests
    load File.dirname(__FILE__) + '/overload_rake_for_tests.rb'
  end

  def get_task_names
    Rake.application.tasks.collect { |task| task.name }
  end

  def assert_cache_exists f
    assert_equal true, File.exists?("#{FRAGMENT_CACHE_PATH}/#{f}.cache"), "#{f}.cache DONT EXIST and it SHOULD"
  end

  def assert_cache_dont_exist f
    assert_equal false, File.exists?("#{FRAGMENT_CACHE_PATH}/#{f}.cache"), "#{f}.cache EXISTS and it SHOULD NOT"
  end


  # Busca en todos los emails uno que contenga el texto indicado
  def assert_email_with_text(some_text)
    found = false
    ActionMailer::Base.deliveries.each do |eml|
      if eml.encoded.index(some_text)
        found = true
        break
      else
        Rails.logger.debug("#{some_text} not found in #{eml.encoded}")
      end
    end
    assert found
  end


  def assert_count_increases(model, &block)
    m = :count
    begin
      initial_count = model.send(m)
    rescue
      m = :size
      initial_count = model.size
    end
    yield
    assert_equal initial_count + 1, model.send(m)
  end

  def assert_count_decreases(model, &block)
    m = :count
    begin
      initial_count = model.send(m)
    rescue
      m = :size
      initial_count = model.size
    end
    yield
    assert_equal initial_count - 1, model.send(m)
  end

  def uncompress_feedvalidator2(zipfile, dst_dir)
    FileUtils.mkdir_p(dst_dir)
    system ("tar xfz #{zipfile} -C #{dst_dir}")
  end

  def assert_valid_feed2(content=@response.body)
    validate = "#{Rails.root}/script/feedvalidator2/demo.py"
    bname = File.dirname(validate)
    self.uncompress_feedvalidator2("#{bname}.tar.gz", "#{bname}/..") unless File.exists?(validate)
    path = Pathname.new("#{Rails.root}/tmp")
    Tempfile.open('feed', path.cleanpath) do |tmpfile|
      tmpfile.write(content)
      tmpfile.flush
      result = `python "#{validate}" "#{tmpfile.path}" A`
      unless result =~ /No errors or warnings/
        out = ''
        i = 1
        content.split("\n").each { |l| out << i.to_s << ': ' << l << "\n"; i += 1 }
        raise "Feed did not validate: #{result}\n#{out}"
      end
    end
  end

  # Tests that a cookie named +name+ does not exist. This is useful
  # because cookies['name'] may be nil or [] in a functional test.
  #
  # assert_no_cookie :chocolate
  def assert_no_cookie(name, message="")
    cookie = cookies[name.to_s]
    msg = build_message(message, "no cookie expected but found <?>.", name)
    assert_block(msg) { cookie.nil? or (cookie.kind_of?(Array) and cookie.blank?) }
  end

  protected
  def assert_call_or_value(name, options, cookie, message="")
    case
      when options[name].respond_to?(:call)
      msg = build_message(message,
                  "expected result of <?> block to be true but it was false.", name.to_s)
      assert(options[name].call(cookie.send(name)), msg)
    else
      msg = build_message(message, "expected cookie <?> to be <?> but it was <?>.",
      name.to_s, options[name], cookie.send(name))
      assert_equal(options[name], cookie.send(name), msg)
    end if options.key?(name)
  end
end

module TestRequestMixings
    # Hasta que salga rails 2.3.3
    def recycle!
      @env["action_controller.request.request_parameters"] = {}
      self.query_parameters = {}
      self.path_parameters = {}
      @headers, @request_method, @accepts, @content_type = nil, nil, nil, nil
    end
end
ActionController::TestRequest.send :include, TestRequestMixings
