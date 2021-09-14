ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
  end
  
  def test_history
    get "/history.txt"
    
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "2014 - Ruby 2.2 released.")
  end
  
  def test_for_nonexistent_file
    get "/notafile.txt"
  
    assert_equal(302, last_response.status)
    
    get last_response["Location"]
    
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "notafile.txt doesn't exist")
    
    get "/"
    assert_equal(200, last_response.status)
    refute_includes(last_response.body, "notafile.txt doesn't exist")
  end
end