# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../cms'

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

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
    create_document('about.md')
    create_document('changes.txt')

    get '/'

    assert_two_hundred
    assert_html_content_type
    assert_body_includes('about.md')
    assert_body_includes('changes.txt')
  end

  def test_viewing_text_document
    create_document('history.txt', 'Ruby 0.95 released')

    get '/history.txt'
    assert_two_hundred
    assert_plain_text_content_type
    assert_body_includes('Ruby 0.95 released')
  end

  def test_viewing_markdown_document
    create_document('about.md', 'Ruby is...')

    get '/about.md'
    assert_two_hundred
    assert_html_content_type
    assert_body_includes('<p>Ruby is...</p>')
  end

  def test_document_not_found
    get '/notafile.ext'

    assert_three_o_two
    get last_response['location']

    assert_two_hundred
    assert_body_includes("notafile.ext doesn't exist")
  end

  def test_editing_document
    create_document('changes.txt')

    get '/changes.txt/edit'

    assert_two_hundred
    assert_body_includes('<textarea')
    assert_body_includes('<button type="submit"')
  end

  def test_updating_document
    post '/history.txt', content: 'new content'

    assert_three_o_two
    get last_response['Location']

    assert_body_includes('history.txt file has been updated')

    get 'history.txt'
    assert_two_hundred
    assert_body_includes('new content')
  end
end
