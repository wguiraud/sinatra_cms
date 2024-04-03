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

root = File.expand_path(__dir__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    render_markdown(content)
  end
end

get '/' do
  @files = Dir.glob("#{root}/data/*").map do |path|
    File.basename(path)
  end

  erb :index
end

get '/:file_name' do
  file_path = "#{root}/data/#{params[:file_name]}"

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:error] = "#{params[:file_name]} doesn't exist!"
    redirect '/'
  end
end

get "/:file_name/edit" do 
  @file_name = params[:file_name]

  file_path = "#{root}/data/#{params[:file_name]}"

  @file_content = File.read(file_path)

  erb :edit_file
end

post "/:file_name" do 
  file_name = params[:file_name]

  file_path = "#{root}/data/#{params[:file_name]}"

  File.open(file_path, 'w') do |file| 
    file.write(params[:content])
  end

  session[:success] = "The #{file_name} file has been updated" 
  redirect "/"
end

