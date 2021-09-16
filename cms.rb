require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"
require "redcarpet"
require "fileutils"
require "yaml"

configure do
  set :erb, :escape_html => true
  enable :sessions
  set :session_secret, 'secret'
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def signed_in?
  session[:username]
end

def not_signed_in
  unless signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  
  erb :index
end

get "/new" do
  not_signed_in
  
  erb :new_file
end

get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} doesn't exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  not_signed_in
  
  file_path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @file_contents = File.read(file_path)
  
  erb :edit_file
end

post "/new" do
  not_signed_in
  
  new_filename = params[:filename].to_s
  
  if new_filename.empty?
    session[:message] = "A name is required."
    status 422
    erb :new_file
  elsif ![".md", ".txt"].include?(File.extname(new_filename))
    session[:message] = "Please include a valid extension, '.md' or '.txt'."
    status 422
    erb :new_file
  else
    file_path = File.join(data_path, new_filename)
    File.write(file_path, "")
    
    session[:message] = "#{new_filename} was created."
    redirect "/"
  end
end

post "/:filename" do
  not_signed_in
  
  file_path = File.join(data_path, params[:filename])
  
  File.write(file_path, params[:content])
  
  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

post "/:filename/delete" do
  not_signed_in
  
  file_path = File.join(data_path, params[:filename])
  File.delete(file_path)
  
  session[:message] = "#{params[:filename]} was deleted."
  redirect "/"
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  credentials = load_user_credentials
  
  if credentials[params[:username]] == params[:password]
    session[:username] = params[:username] 
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    @username = params[:username]
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end