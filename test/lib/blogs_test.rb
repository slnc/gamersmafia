# -*- encoding : utf-8 -*-
require 'test_helper'

class BlogsTest < ActiveSupport::TestCase
  test "top_bloggers should run" do
    Blogs.top_bloggers
  end
end
