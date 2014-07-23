#!/usr/bin/env ruby
#
# This script creates a template directory structure for Ansible roles and projects as is required by
# the BSkyb OTT Cloud Platform team to comply with agreed directory layout
#
# Author: Ogonna Iwunze (ogonna.iwunze@bskyb.com)
# Date: 08/04/2014
#
# ruby ansible_boilerplate.rb --create [role|project]

require 'optparse'
require 'pp'

#ToDo:
#  add readme template 

class AnsibleTemplate

  def initialize(type, name, base_dir)
    @template_type = type
    @name = name
    @base_dir = base_dir
  end

  def create_dir_structure

    case @template_type
      when 'role'
        create_role_dir_structure
      when 'project'
        create_project_dir_structure
    end
  end


  def create_role_dir_structure
    puts "Creating directory structure for role: #{@name}"
    role_dir    = "#{@base_dir}/roles/#{@name}"
    sub_dirs    = %w{ files meta tasks templates vars }
    readme_file = "#{role_dir}/README.md"

    # Create role directory
    Dir.mkdir(role_dir)  unless Dir.exists? role_dir

    # Create sub-directories
    sub_dirs.each do |d|
      full_path = "#{role_dir}/#{d}"
      main_yml  = "#{full_path}/main.yml"
      Dir.mkdir(full_path) unless Dir.exists? full_path
      # Create main.yml
      File.open(main_yml, 'w') { |f| f.puts '---' }  unless File.exists? main_yml
    end

    # Create README.md
    File.open(readme_file, 'w') { |f| f.puts '' } unless File.exists? readme_file
  end


  def create_project_dir_structure
    puts "Creating directory structure for project: #{@name}"
    project_dir = "#{@base_dir}/projects/#{@name}"
    tiers       = %w{ webtier apptier dbtier }
    envs        = %w{ devops stage uat }
    cloud_type  = 'aws'

    main_playbook = 'site.yml'

    # Build list of project files
    p_files = [ 'README.md', main_playbook ]
    tiers.each do |t|
      p_files << "#{t}_vars.yml"                   # Variables file
      p_files << "#{t}.yml"                       # Tier Playbook file
    end

    envs.each do |e|
      p_files << "#{cloud_type}_#{e}_env.yml"     # Environment file
      p_files << "#{e}_hosts"                     # Inventory file
    end

    puts p_files
    # Create role directory
    Dir.mkdir(project_dir) unless Dir.exists? project_dir

    p_files.each do |pf|
      if pf.include? '.yml'
        File.open(File.join(project_dir, pf), 'w') { |f| f.puts '---' } unless File.exists? pf
      else
        File.open(File.join(project_dir, pf), 'w') { |f| f.puts '' } unless File.exists? pf
      end
    end
  end

end


#######################################
#==   Options parsing starts here  ==#
######################################
options = {}

if __FILE__ == $0

  opt_parser = OptionParser.new do|opt|
    opt.banner = "Usage:
      This script creates a template directory structure for an ansible role or project directory. Ensure this script is
      run from within Ansible directory (e.g. /etc/ansible or /path/to/ansible)
            To create a role template
                ruby #{$0} -c role -n <role_name>
            To create a project template
                ruby #{$0} -c role -n <role_name>
      Note:
        A role is a collection of tasks that can be applied to different playbooks
        A project is how OTT CP team has organised the configs and playbooks required to deploy an application
    "
    opt.separator  ""
    opt.separator  "Options:"
    opt.on '-c', '--create [role|project]', String, 'Create a template [role|project] directory structure' do |t|
      options[:template_type] = t
    end

    opt.on '-n', '--name Name', String, 'Name of directory to create' do |n|
      options[:name] = n
    end

    opt.on( '-h', '--help', 'Display this screen' ) do
      puts opt
      exit
    end
  end
  opt_parser.parse!

  base_dir = './'
  mandatory = [:template_type, :name]
  missing = mandatory - options.keys

  if options.empty?
    puts opt_parser
  elsif ! missing.empty?
    puts "Missing argument(s): #{missing.to_s}"
  elsif options[:template_type] && options[:name]
    AnsibleTemplate.new(options[:template_type], options[:name], base_dir).create_dir_structure
  else
    puts opt_parser
  end
end

