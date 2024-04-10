# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test' # makes last_response available
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

  def assert_four_twenty_two
    assert_equal 422, last_response.status
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

  def session
    last_request.env['rack.session']
  end

  def admin_session
    { 'rack.session' => { username: 'admin' } }
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
    assert_equal "notafile.ext doesn't exist!", session[:message]
  end

  def test_editing_document
    create_document('changes.txt')

    get '/changes.txt/edit', {}, admin_session

    assert_two_hundred
    assert_body_includes('<textarea')

    assert_body_includes('<button type="submit"')
  end

  def test_editing_document_signed_out
    create_document('hello.txt')

    get '/hello.txt/edit'

    assert_three_o_two
    assert_equal 'You must be signed in to do that', session[:message]
  end

  def test_updating_document
    post '/history.txt', { content: 'new content' }, admin_session

    assert_three_o_two
    assert_equal 'The history.txt file has been updated', session[:message]

    get 'history.txt' # new request to check if the document does include the new content
    assert_two_hundred
    assert_body_includes('new content')
  end

  def test_updating_document_signed_out
    post '/history.txt', content: 'new content'

    assert_three_o_two
    assert_equal 'You must be signed in to do that', session[:message]
  end

  def test_view_new_document_form
    get '/new', {}, admin_session

    assert_two_hundred
    assert_body_includes('<label for="filename">Add new document:</label>')
    assert_body_includes('<input name="filename" id="filename"/>')
    assert_body_includes('<button type="submit">Create</button>')
  end

  def test_create_new_document
    post '/create', { filename: 'hello.txt' }, admin_session
    assert_three_o_two
    assert_equal 'The hello.txt file has been created', session[:message]

    get '/'
    assert_body_includes('hello.txt')
  end

  def test_create_new_document_signed_out
    post '/create', filename: 'hello.txt'

    assert_three_o_two
    assert_equal 'You must be signed in to do that', session[:message]
  end

  def test_create_new_document_without_correct_filename
    post '/create', { filename: 'HELLO.TXT' }, admin_session

    assert_four_twenty_two
    assert_body_includes('the name is not valid')
  end

  def test_deleting_document
    create_document('hello.txt')

    post '/hello.txt/delete', {}, admin_session
    assert_three_o_two
    assert_equal 'The hello.txt file has been deleted!', session[:message]

    get '/'
    refute_body_includes("<a href='hello.txt'")
  end

  def test_deleting_document_signed_out
    create_document('hello.txt')

    post '/hello.txt/delete'
    assert_three_o_two
    assert_equal 'You must be signed in to do that', session[:message]
  end

  def test_sign_in_link
    get '/'

    assert_two_hundred
    assert_body_includes("<p class='user-status'>")
    assert_body_includes("<a href='/users/signin'>Sign In</a>")
  end

  def test_signin_form
    get '/users/signin'

    assert_two_hundred
    assert_body_includes("<label for='username'>Username:")
    assert_body_includes("<input name='username' id='username' value=")
    assert_body_includes("<label for='password'>Password:")
    assert_body_includes("<input name='password' id='password' type='password'/>")
    assert_body_includes("<button type='submit'>Sign In</button>")
  end

  def test_signing_in_successfully
    post '/users/signin', username: 'admin', password: 'secret'
    assert_three_o_two
    assert_equal 'Welcome', session[:message]
    assert_equal 'admin', session[:username]

    get last_response['Location']
    assert_body_includes("<p class='user-status'>Signed in as admin.")
    assert_body_includes("<button type='submit'>Sign Out</button>")
  end

  def test_signing_in_unsuccessfully
    post '/users/signin', username: '    ', password: '     '
    assert_four_twenty_two
    assert_nil session[:username]
    assert_body_includes('invalid username or password')
  end

  def test_signing_out
    get '/', {}, { 'rack.session' => { username: 'admin' } }
    assert_body_includes('Signed in as admin')

    post '/users/signout'
    assert_equal 'You have been signed out.', session[:message]

    get last_response['Location']

    assert_nil session[:username]
    assert_body_includes('Sign In')
  end
end
