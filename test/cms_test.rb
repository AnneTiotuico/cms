ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  def setup
    FileUtils.mkdir_p(data_path)
  end
  
  def teardown
    FileUtils.rm_rf(data_path)
  end
  
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end
  
  def session
    last_request.env["rack.session"]
  end

  def test_index
    create_document("about.md")
    create_document("changes.txt")
    
    get "/"
    
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.md")
    assert_includes(last_response.body, "changes.txt")
  end
  
  def test_view_textfile
    create_document("history.txt", "2014 - Ruby 2.2 released.")
    
    get "/history.txt"
    
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "2014 - Ruby 2.2 released.")
  end
  
  def test_for_nonexistent_file
    get "/notafile.txt"
  
    assert_equal(302, last_response.status)
    assert_includes("notafile.txt doesn't exist.", session[:message])
  end
  
  def test_markdown_file
    create_document("about.md", "<h1>Ruby is...</h1>")
    
    get "/about.md"
    
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "<h1>Ruby is...</h1>")
  end
  
  def test_editing_document
    create_document("changes.txt")
    
    get "/changes.txt/edit"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, %q(<button type="submit"))
  end

  def test_updating_document
    post "/changes.txt", content: "new content"

    assert_equal(302, last_response.status)
    assert_includes("changes.txt has been updated.", session[:message])

    get "/changes.txt"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "new content")
  end
  
  def test_view_new_file_form
    get "/new"
    
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<input")
    assert_includes(last_response.body, %q(<button type="submit"))
  end
  
  def test_create_new_file
    post "/new", filename: "text.txt"
    
    assert_equal(302, last_response.status)
    assert_includes("text.txt was created.", session[:message])
    
    get "/"
    assert_includes(last_response.body, "text.txt")
  end
  
  def test_create_new_file_without_filename
    post "/new", filename: ""
    
    assert_equal(422, last_response.status)

    assert_includes(last_response.body, "A name is required")
  end
  
  def test_create_new_file_without_extension
    post "/new", filename: "test"
    
    assert_equal(422, last_response.status)

    assert_includes(last_response.body, "Please include a valid extension, '.md' or '.txt'.")
  end
  
  def test_delete_file
    create_document("test.txt")
    
    post "/test.txt/delete"
    
    assert_equal(302, last_response.status)
    assert_includes("test.txt was deleted.", session[:message])
    
    get "/"
    refute_includes(last_response.body, %q(href="/test.txt"))
  end
  
  def test_signin_form
    get "/users/signin"
    
    assert_equal 200,(last_response.status)
    assert_includes(last_response.body, "<input")
    assert_includes(last_response.body, %q(<button type="submit"))
  end
  
  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal(302, last_response.status)
    assert_includes("Welcome!", session[:message])
    assert_includes("admin", session[:username])
    
    get last_response["Location"]
    assert_includes(last_response.body, "Signed in as admin")
  end
  
  def test_signin_with_bad_credentials
    post "/users/signin", username: "test", password: "test"
    assert_equal(422, last_response.status)
    assert_nil(session[:message])
    assert_includes(last_response.body, "Invalid Credentials")
  end
  
  def test_signout
    get "/", {}, {"rack.session" => { username: "admin" } }
    assert_includes(last_response.body, "Signed in as admin")
    
    post "/users/signout" 
    
    assert_includes("You have been signed out.", session[:message])
    
    get last_response["Location"]
    assert_nil session[:message]
    assert_includes(last_response.body, %q(<button type="submit">Sign In))
  end
end