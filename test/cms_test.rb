ENV["RACK_ENV"]="test" 

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms'

class CmsTest < Minitest::Test
  include Rack::Test::Methods 

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_valid_file_request
    get "/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Yukihiro Matsumoto"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "1995 - Ruby 0.95 released."

    get "/history.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "2022 - Ruby 3.2 released."
  end

  def test_invalid_file_request
    get "/:hello.txt"
    
    assert_equal 302, last_response.status

    get last_response["Location"] 

    assert_equal 200, last_response.status
    assert_includes last_response.body, "hello.txt doesn't exist!"

    get "/"
    refute_includes last_response.body, "hello.txt doesn't exist!"
  end

end
 
