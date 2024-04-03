# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms'

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def assert_two_hundred
    assert_equal 200, last_response.status
  end

  def assert_three_o_two
    assert_equal 302, last_response.status
  end

  def assert_html_content_type
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  end

  def assert_plain_text_content_type
    assert_equal 'text/plain', last_response['Content-Type']
  end

  def assert_body_includes(text)
    assert_includes last_response.body, text
  end

  def refute_body_includes(text)
    refute_includes last_response.body, text
  end

  def test_index
    get '/'

    assert_two_hundred
    assert_html_content_type
    assert_body_includes('about.txt')
    assert_body_includes('about.md')
    assert_body_includes('changes.txt')
    assert_body_includes('history.txt')
  end

  def test_document_not_found
    get '/:hello.txt'

    assert_three_o_two
    get last_response['Location']

    assert_two_hundred
    assert_body_includes("hello.txt doesn't exist!")

    get '/'
    assert_two_hundred
    refute_body_includes("hello.txt doesn't exist!")
  end

  def test_viewing_text_document
    get '/about.txt'
    assert_two_hundred
    assert_plain_text_content_type
    assert_body_includes("\n")
  end

  def test_viewing_markdown_document
    get '/about.md'
    assert_two_hundred
    assert_html_content_type
    assert_body_includes('<h1>')
  end

  def test_editing_document
    get '/changes.txt/edit'
    assert_two_hundred
    assert_html_content_type
    assert_body_includes('Edit content of changes.txt:')
    assert_body_includes('<textarea')
    assert_body_includes('<button type="submit"')
  end

  def test_updating_document
    post "/history.txt", content: "new content"

    assert_three_o_two
    get last_response["Location"]

    get "history.txt"
    assert_two_hundred
    assert_body_includes('new content') 


  end
end
