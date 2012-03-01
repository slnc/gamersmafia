require 'test_helper'

class CountryTest < ActiveSupport::TestCase

  def setup
    @country = Country.find(1)
  end

  test "truth" do
    assert_kind_of Country,  @country
  end
end
