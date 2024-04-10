# frozen_string_literal: true

require 'redcarpet'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'tilt/erubis'
require 'rubocop-minitest'

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

#root = File.expand_path("..", __FILE__) # => "/home/launchschool/Documents/LS/LS175/Project_File_Based_CMS_1/data"

def data_path
	if ENV["RACK_ENV"] == "test"
		File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def create_document(name, content="")
  File.open(File.join(data_path, name), 'w') do |file|
    file.write(content)
  end
end

def valid_filename?(filename)
  pattern = /^[a-z0-9_]{1,20}\.[a-z]{1,4}$/  # allows between 1 and 20 lowercase alphabetic characters for the basename including underscores. extention name between 1 and 4 lowercase alphabetic characters 

  filename.match?(pattern) 
end

def user_signed_in?
  session[:username] == 'admin'
end

def require_signed_in_user 
  unless user_signed_in?
    session[:message] = "You must be signed in to do that"
    redirect '/'
  end
end

get '/' do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :index
end

get "/new" do 
  require_signed_in_user
  erb :new
end

post "/create" do 
  require_signed_in_user

  if valid_filename?(params[:filename])
    create_document(params[:filename])
    session[:message] = "The #{params[:filename]} file has been created" 
    redirect "/"
  else
    session[:message] = "the name is not valid"
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

get "/:file_name/edit" do 
  require_signed_in_user
  
  @file_name = params[:file_name]

  file_path = File.join(data_path, params[:file_name])

  @file_content = File.read(file_path)

  erb :edit_file
end

post "/:file_name" do 
  require_signed_in_user

  file_name = params[:file_name]

  file_path = File.join(data_path, params[:file_name])

  File.open(file_path, 'w') do |file| 
    file.write(params[:content])
  end

  session[:message] = "The #{file_name} file has been updated" 
  redirect "/"
end

post "/:file_name/delete" do 
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
  if params[:username] == 'admin' && params[:password] == 'secret'
    session[:username] = params[:username] 
    session[:message] = 'Welcome'
    redirect '/'
  else 
    session[:message] = 'invalid username or password'
    status 422 #request contains semantic errors
    erb :signin
  end
end

post '/users/signout' do 
  session.delete(:username) #how do you access the session while testing? 
  session[:message] = "You have been signed out."
  redirect "/"
end
