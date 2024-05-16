# frozen_string_literal: true

require 'redcarpet'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'tilt/erubis'
require 'rubocop-minitest'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when '.md'
    erb render_markdown(content)
  else
    headers['Content-Type'] = 'text/plain'
    content
  end
end

# root = File.expand_path("..", __FILE__) # => "/home/launchschool/Documents/LS/LS175/Project_File_Based_CMS_1/data"

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('test/data', __dir__)
  else
    File.expand_path('data', __dir__)
  end
end

def create_document(name, content = '')
  File.open(File.join(data_path, name), 'w') do |file|
    file.write(content)
  end
end

def valid_filename?(filename)
  pattern = /^[a-z0-9_]{1,20}\.[a-z]{1,4}$/ # allows between 1 and 20 lowercase alphabetic characters for the basename including underscores. extention name between 1 and 4 lowercase alphabetic characters

  filename.match?(pattern)
end

def valid_credentials?(username, password)
  username_pattern = /^[a-zA-Z]{1,20}[_\.]?[a-zA-Z]{1,20}$/ # allows between 1 and 20 lowercase alphabetic characters for the basename including underscores. extention name between 1 and 4 lowercase alphabetic characters
  password_pattern = /^[a-zA-Z0-9!@#$%^&*]{1,20}$/ # allows between 1 and 20 lowercase alphabetic characters for the basename including underscores. extention name between 1 and 4 lowercase alphabetic characters

  username.match?(username_pattern) && password.match?(password_pattern)
end


def user_signed_in?
  session[:username] 
end

def require_signed_in_user
  return if user_signed_in?

  session[:message] = 'You must be signed in to do that'
  redirect '/'
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/users2.yml", __FILE__)
  else
    File.expand_path("../users2.yml", __FILE__)
  end

  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password # this is BCrypt#==(secret) method!!!!which has a special implementation!!!!
  else 
    false
  end
end

def get_current_time_as_string
  Time.now.strftime('%Y-%m-%d-%H:%M:%S')
end

def clean_up_filename(filename)
  if filename.include?("copy")
    filename.gsub!(/-copy-\d{4}-\d{2}-\d{2}-\d{2}:\d{2}:\d{2}/, "")
  else
    filename
  end
end

def duplicate_file(dfn, fp)
  FileUtils.touch(dfn)

  FileUtils.copy_file(fp, dfn)

  duplicated_file_content = File.read(dfn)

  create_document(dfn, content = duplicated_file_content)
end

get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :index
end

get '/new' do
  require_signed_in_user
  erb :new
end

post '/create' do
  require_signed_in_user

  if valid_filename?(params[:filename])
    create_document(params[:filename])
    session[:message] = "The #{params[:filename]} file has been created"
    redirect '/'
  else
    session[:message] = 'the name is not valid'
    status 422
    erb :new
  end
end

get '/:file_name' do
  file_path = File.join(data_path, params[:file_name])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:file_name]} doesn't exist!"
    redirect '/'
  end
end

get '/:file_name/edit' do
  require_signed_in_user

  @file_name = params[:file_name]

  file_path = File.join(data_path, params[:file_name])

  @file_content = File.read(file_path)

  erb :edit_file
end

post '/:file_name' do
  require_signed_in_user

  file_name = params[:file_name]

  file_path = File.join(data_path, params[:file_name])

  File.open(file_path, 'w') do |file|
    file.write(params[:content])
  end

  session[:message] = "The #{file_name} file has been updated"
  redirect '/'
end

post '/:file_name/delete' do
  require_signed_in_user

  file_name = params[:file_name]

  file_path = File.join(data_path, params[:file_name])

  File.delete(file_path)

  session[:message] = "The #{file_name} file has been deleted!"
  redirect '/'
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  credentials = load_user_credentials
  username = params[:username]

  if valid_credentials?(username, params[:password])

    session[:username] = username 
    session[:message] = 'Welcome'
    redirect '/'
  else
    session[:message] = 'invalid username or password'
    status 422 # request contains semantic errors
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username) # how do you access the session while testing?
  session[:message] = 'You have been signed out.'
  redirect '/'
end

post '/:file_name/duplicate' do 
  require_signed_in_user

  file_path = File.join(data_path, params[:file_name])

  clean_up_filename(params[:file_name])

  duplicated_file_name = "#{clean_up_filename(params[:file_name])}-copy-#{get_current_time_as_string}"

  duplicate_file(duplicated_file_name, file_path)
# 
  # ensure that the user is signed in when requiring to duplicate the file
  # naming convention when the duplicated file is created 
  # ensuring that the duplicated file is saved correctly
#
  session[:message] = "The #{params[:file_name]} file has been duplicated!"
  redirect '/'


end
