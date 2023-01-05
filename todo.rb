# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require 'securerandom'
secret = SecureRandom.hex(32)

configure do
  enable :sessions
  set :session_secret, secret
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

# returns an array of list names
def list_names
  lists = session[:lists]
  lists.map { |list| list[:name] }
end

# returns a boolean representing validity of given list name
def valid_name?(name)
  error_message(name) == 'no error'
end

# returns error message for invalid list name, or "no error" if name is valid
def error_message(name)
  if !(1..100).cover?(name.length)
    return 'List name must be between 1 and 100 characters.'
  elsif list_names.include?(name)
    return "'#{name}' is already a list. Name must be unique."
  end

  'no error'
end

def generate_id
  session[:current_id] = 0 if session[:current_id].nil?
  id = session[:current_id]
  session[:current_id] += 1
  id
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  p @lists
  @lists = session[:lists]
  erb :lists
end

# Render 'new list' form
get '/lists/new' do
  erb :new_list
end

# get specific list or create new list
get '/lists/:id' do
  @list = @lists[params[:id].to_i]
  erb :list
end

# edit an existing todo list
get '/lists/:id/edit' do
  @id = params[:id].to_i
  @list = @lists[@id]
  erb :edit_list
end


# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  if valid_name?(list_name)
    session[:lists] << { name: list_name, todos: [] , id: generate_id}
    session[:success] = 'The list has been created.'
    redirect '/lists'
  else
    session[:error] = error_message(list_name)
    erb :new_list
  end
end

# Change list name
post '/lists/:id/edit' do
  new_list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = @lists[@id]
  old_name = @list[:name]

  # update
  if valid_name?(new_list_name)
    session[:lists][@id][:name] = new_list_name
    session[:success] = "The list '#{old_name}' has been renamed to '#{new_list_name}'"
    redirect '/lists'
  else
    session[:error] = error_message(new_list_name)
    erb :edit_list
  end
end

# delete list
post '/lists/:id/destory' do
end
