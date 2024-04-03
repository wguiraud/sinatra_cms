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

  def asset_plain_text_content_type
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

  def test_valid_file_request
    get '/about.txt'

    assert_two_hundred
    assert_body_includes('Yukihiro Matsumoto')

    get '/changes.txt'
    assert_two_hundred
    assert_body_includes('1995 - Ruby 0.95 released.')

    get '/history.txt'
    assert_two_hundred
    assert_body_includes('2022 - Ruby 3.2 released.')
  end

  def test_invalid_file_request
    get '/:hello.txt'

    assert_three_o_two
    get last_response['Location']

    assert_two_hundred
    assert_body_includes("hello.txt doesn't exist!")

    get '/'
    refute_body_includes("hello.txt doesn't exist!")
  end

  def test_viewing_txt_markdown_files
    get '/about.txt'

    assert_two_hundred
    asset_plain_text_content_type
    assert_body_includes("\n")

    get '/about.md'
    assert_two_hundred
    assert_html_content_type
    assert_body_includes('<h1>')
  end
end
