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
    assert_includes(last_response.body, "about.md")
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
  
  def test_markdown_file
    get "/about.md"
    
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "<h1>Ruby is...</h1>")
  end
  
  def test_editing_document
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_updating_document
    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
end