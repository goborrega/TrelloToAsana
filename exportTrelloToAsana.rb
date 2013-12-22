#!/usr/bin/env ruby
 
require "rubygems"
require 'trello'
require 'asana'
require 'yaml'

cnf = YAML::load(File.open('config.yml'))

 
# Trello keys
TRELLO_DEVELOPER_PUBLIC_KEY = cnf['trello']['developer_public_key']
TRELLO_MEMBER_TOKEN = cnf['trello']['member_token']

# Asana keys
ASANA_API_KEY = cnf['asana']['api_key']
ASANA_ASSIGNEE = 'me'
 

def get_option_from_list(list, title, attribute)
  i=0

  while i == 0 do
    puts title
    
    list.each do |item|
      i += 1
      puts "  #{i}) #{item.send(attribute)}"
    end

    i = gets.chomp.to_i
    i = 0 if i <= 0 && i > list.size    
  end
  return i - 1
end
 

Trello.configure do |config|
  config.developer_public_key = TRELLO_DEVELOPER_PUBLIC_KEY
  config.member_token = TRELLO_MEMBER_TOKEN
end

Asana.configure do |client|
  client.api_key = ASANA_API_KEY
end

workspaces = Asana::Workspace.all

boards = Trello::Board.all
boards.each do |board|
  next if board.closed?
  
  puts "\n=== Export Board #{board.name}? [yn]"
  next unless gets.chomp == 'y' 

  # Which workspace to put it in
  workspace = workspaces[get_option_from_list(workspaces, 
    "Select destination workplace", 
    "name")]
  puts "Using workspace #{workspace.name}"

  # Which project to associate
  project = workspace.projects[get_option_from_list(workspace.projects, 
    "Select destination project", 
    "name")]
  puts " -- Using project #{project.name} --"

  puts ' -- Getting users --'
  users = workspace.users

  board.lists.each do |list|
  
    puts " - #{list.name}:"

    list.cards.reverse.each do |card|
      puts "  - Card #{card.name}, Due on #{card.due}"

      # Create the task
      t = Asana::Task.new
      t.name = card.name
      t.notes = card.desc
      t.due_on = card.due.to_date if !card.due.nil?

      # Assignee - Try to find by name. Otherwise will be empty
      t.assignee = nil
      if !card.member_ids.empty? then
        userList = users.select { |u| 
          u.name == card.members[0].full_name
        }
        t.assignee = userList[0].id unless userList.empty?
      end

      task = workspace.create_task(t.attributes)
      
      #Project
      task.add_project(project.id)

      #Stories / Trello comments
      comments = card.actions.select {|a| a.type == 'commentCard'}
      comments.each do |c|
        task.create_story({:text => c.data['text']})
      end

      #Subtasks
      card.checklists.each do |checklist|
        checklist.check_items.each do |checkItem|
          st = Asana::Task.new
          st.name = checkItem['name']
          st.assignee = nil
          task.create_subtask(st.attributes)
        end
      end

    end

     # Create each list as an aggregator if it has cards in it
    if !list.cards.empty? then
      task = workspace.create_task({name: "#{list.name}:", assignee: nil})
      task.add_project(project.id)
    end

  end

  
end
