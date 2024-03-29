ENV["RACK_ENV"]="test" # to let the sinatra object know that it doesn't have to run the web server when the tests are running!

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

  def test_document
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

end
 
