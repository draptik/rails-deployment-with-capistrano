#!/bin/bash
##
## This script creates a minimal Rails project, does some version
## control stuff, and uses Capistrano to deploy the application to a
## production server.

# ===================================================================
# USER SETTINGS =====================================================
# ===================================================================

# IMPORTANT: PLEASE EDIT TO YOUR NEEDS!

# Your project name
PROJECTNAME="demo"

# Your default tmp folder
TMPDIR="/home/${USER}/tmp"

# Your version control system (currently only Mercurial (=Hg) or Git)
VCS="git"
# VCS="hg"

# Your server name for version control repository
REPOSERVER=`uname -n`

# Your destination server (the place you want to deploy your
# application to)
APPSERVER="ubuntu-server-10-04"


# ===================================================================
# CHECK IF ALL REQUIRED PROGRAMS ARE INSTALLED ======================
# ===================================================================
## Check if Ruby is present
RUBY=`which ruby`
[ ! $RUBY ] && echo "Ruby not found. Aborting." && exit -1

## Check if Rails is present
RAILS=`which rails`
[ ! ${RAILS} ] && echo "Rails not found. Aborting." && exit -1

## Check if Git is present
if [ ${VCS} == "git" ]; then
    GIT=`which git`
    [ ! ${GIT} ] && echo "Git not found. Aborting." && exit -1
fi

## Check if Hg is present
if [ ${VCS} == "git" ]; then
    HG=`which hg`
    [ ! ${HG} ] && echo "Hg not found. Aborting." && exit -1
fi

## Check if Capistrano is present
CAPIFY=`which capify`
[ ! ${CAPIFY} ] && echo "Capify not found. Aborting." && exit -1
CAP=`which cap`
[ ! ${CAP} ] && echo "Cap not found. Aborting." && exit -1

# ===================================================================
# PROJECT DIRECTORIES ===============================================
# ===================================================================
## Check if tmp dir is present; create it, if it does not exist
[ ! -d ${TMPDIR} ] && mkdir ${TMPDIR}
echo "cd " ${TMPDIR}
cd ${TMPDIR}

## Check if project dir is present: Delete if present; else create it
PRJDIR="${TMPDIR}/${PROJECTNAME}"
if [ -d ${PRJDIR} ]; then
    echo "rm -rf " ${PRJDIR}
    rm -rf ${PRJDIR}
fi

## Switch to Project dir
echo "cd ${TMPDIR}" 
cd "${TMPDIR}"


# ===================================================================
# RAILS: CREATE MINIMAL PROJECT =====================================
# ===================================================================
## Create Rails application within project dir
echo "Creating RAILS application in ${PWD}..."
${RAILS} ${PROJECTNAME} &

## Wait until Rails project has been created
wait
echo "Done creating RAILS project in dir ${PRJDIR}."

## Create Rails Controller "Say" template
echo "cd \"${PRJDIR}\""
cd "${PRJDIR}"
echo "Creating Rails Controller 'Say'..."
${RUBY} script/generate controller Say index

## Create Rails Controller "Say" content "hello"
echo "Creating Rails Controller 'Say' content 'hello'..."
echo \
"class SayController < ApplicationController
  def hello
  end
end" > app/controllers/say_controller.rb

## Create Rails View "Say" content
echo "Creating Rails View 'Say' content..."
echo \
"<html>
   <body>
     <h1>Hello from Intro page!</h1>
   </body>
</html>" > app/views/say/hello.html.erb

## Create minimal index.html for Say controller
echo "Hello World" > app/views/say/index.html.erb

## routes.rb
sed '/# map.root/ a\'"map.root :controller => 'say'"'' \
    config/routes.rb > config/routes.rb.tmp

mv config/routes.rb.tmp config/routes.rb

# ===================================================================
# VERSION CONTROL ===================================================
# ===================================================================
REPO=

cd "${PRJDIR}"
echo "Current dir ${PWD}"

# GIT ===============================================================
if [ ${VCS} == "git" ]; then

# Git init and commit -----------------------------------------------
## Create ignore file for GIT
    echo "Creating .gitignore file..."
    echo \
"db/*.sqlite3
log/*.log
tmp/**/*" > "${PRJDIR}/.gitignore"

    echo "Starting Git commit..."
    cd "${PRJDIR}"
    echo "${GIT} init"
    ${GIT} init
    echo "${GIT} add ."
    ${GIT} add .
    echo "${GIT} commit -m \"initial commit\""
    ${GIT} commit -m "initial commit"
    
    echo "FINISHED COMMITING GITIGNORE. . . ."
# GIT push to Git-Server --------------------------------------------
## Option 1: Git clone to local file system
## Git local setup (can be replaced by Git server on foreign machine)
    GITREPO_BASE="${TMPDIR}/git"
    [ ! -d ${GITREPO_BASE} ] && mkdir -p "${GITREPO_BASE}"

    # Create Git repo -----------------------------------------------
    GITREPO_BASE="${TMPDIR}/git"
    [ -d ${GITREPO_BASE} ] && rm -rf "${GITREPO_BASE}" && mkdir -p "${GITREPO_BASE}"

    # Clone bare..
    echo "${GIT} clone --bare . ${GITREPO_BASE}/${PROJECTNAME}.git"
    ${GIT} clone --bare . ${GITREPO_BASE}/${PROJECTNAME}.git

    # Define Clone as master..
    echo "Defining ${GITREPO_BASE}/${PROJECTNAME}.git as git origin..."
    ${GIT} remote add origin "${GITREPO_BASE}/${PROJECTNAME}.git"
    ${GIT} push origin master

    GITREPO="${GITREPO_BASE}/${PROJECTNAME}.git"
    REPO="${GITREPO}"
    echo "--> ${REPO}"

# ## TODO Option 2: Git push to remote server (ie NAS-Box, GitHub, etc)
# # echo "${GIT} remote add origin ssh://${USER}@`uname -n`/${GITREPO}/${PROJECTNAME}.git"
# # ${GIT} remote add origin ssh://${USER}@`uname -n`/${GITREPO}/${PROJECTNAME}.git
# # echo "${GIT} push origin master"
# # ${GIT} push origin master

fi

# MERCURIAL (hg) ====================================================
if [ ${VCS} == "hg" ]; then

    # Create ignore file for Mercurial ------------------------------
    echo "Creating .hgignore file..."
    echo \
    "syntax: glob
db/*.sqlite3
log/*.log
tmp/*
tmp/**/*
*~
.DS_Store" > "${PRJDIR}/.hgignore"

    # Create Mercurial repository -----------------------------------
    HGREPO="${TMPDIR}/hg"
    [ -d ${HGREPO} ] && rm -rf "${HGREPO}" && mkdir -p "${HGREPO}"

    # Commit and clone to repository --------------------------------
    echo "Starting Hg commit..."
    cd "${PRJDIR}"
    echo "${HG} init"
    ${HG} init
    echo "${HG} add ."
    ${HG} add .
    echo "${HG} commit -m \"initial commit\""
    ${HG} commit -m "initial commit"

    echo "${HG} clone . ${HGREPO}"
    ${HG} clone . "${HGREPO}/${PROJECTNAME}"

    REPO="${HGREPO}/${PROJECTNAME}"
fi
# END OF VERSION CONTROL STUFF ======================================


# ===================================================================
# CAPISTRANO ========================================================
# ===================================================================

# Initialize Capistrano =============================================
echo "${CAPIFY} ."
${CAPIFY} .


## Note: Main Capistrano configuration file: config/deploy.rb

echo "Backing up default Capistrano config file config/deploy.rb..."
mv "${PRJDIR}"/config/deploy.rb "${PRJDIR}"/config/deploy.rb.original

echo "Creating config/deploy.rb..."
# Mercurial version  ================================================
if [ ${VCS} == "hg" ]; then
    # echo "Setting up config/deploy.rb for ${VCS}..."
## Mercurial: Note for repository settings: We need 2 slashes after
## the IP to denote an absolute path!
    echo "
set :user, \"${USER}\"
set :domain, \"${APPSERVER}\"
set :application, \"${PROJECTNAME}\"

# Source control management (SCM)
set :repository, \"ssh://#{user}@${REPOSERVER}//${REPO}\"
set :scm, :mercurial
set :scm_verbose, true
set :scm_user, \"#{user}\"
set :scm_password, Proc.new { Capistrano::CLI.password_prompt(\"Mercurial password for #{scm_user}: \") }
set :deploy_to, \"/var/www/#{application}\"

role :app, \"#{domain}\"
role :web, \"#{domain}\"
role :db, \"#{domain}\", :primary => true

# If you are using Passenger mod_rails uncomment this
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run \"#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}\"
  end
end

# We need this to fix the following error message:
#     sudo: no tty present and no askpass program specified 
# For details see: http://groups.google.com/group/capistrano/browse_thread/thread/e79e1e85b084e39a
default_run_options[:pty] = true 
" > "${PRJDIR}"/config/deploy.rb
fi
if [ ${VCS} == "git" ]; then
    echo "
default_environment['PATH']='\$PATH:/var/lib/gems/1.8/bin'
default_environment['GEM_PATH']='\$PATH:/var/lib/gems/1.8/gems'

set :user, \"${USER}\"
set :domain, \"${APPSERVER}\"
set :application, \"${PROJECTNAME}\"

# Source control management (SCM)
set :repository, \"ssh://#{user}@${REPOSERVER}//${REPO}\"
set :scm, :git
set :scm_verbose, true
set :scm_user, \"#{user}\"
set :scm_password, Proc.new { Capistrano::CLI.password_prompt('Git password for #{scm_user}: ') }
set :deploy_to, \"/var/www/#{application}\"

role :app, \"#{domain}\"
role :web, \"#{domain}\"
role :db, \"#{domain}\", :primary => true

# If you are using Passenger mod_rails uncomment this
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run \"#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}\"
  end
end

# We need this to fix the following error message:
#     sudo: no tty present and no askpass program specified 
# For details see: http://groups.google.com/group/capistrano/browse_thread/thread/e79e1e85b084e39a
default_run_options[:pty] = true 
" > "${PRJDIR}"/config/deploy.rb
fi

## Add capify stuff to repository
echo "Adding Capify changes to repository..."
cd ${PRJDIR}

VERSION_CONTROL_COMMAND=
if [ ${VCS} == "hg" ]; then
    VERSION_CONTROL_COMMAND=${HG}
    ${VERSION_CONTROL_COMMAND} addremove
    echo "${VERSION_CONTROL_COMMAND} commit -m\"adding capify stuff\""
    ${VERSION_CONTROL_COMMAND} commit -m"adding capify stuff"
    echo "${VERSION_CONTROL_COMMAND} push \"${HGREPO}/${PROJECTNAME}\""
    ${VERSION_CONTROL_COMMAND} push "${HGREPO}/${PROJECTNAME}"
fi
if [ ${VCS} == "git" ]; then
    VERSION_CONTROL_COMMAND=${GIT}
    ${VERSION_CONTROL_COMMAND} add .
    echo "${VERSION_CONTROL_COMMAND} commit -m\"adding capify stuff\""
    ${VERSION_CONTROL_COMMAND} commit -m"adding capify stuff"

    echo PWD: $PWD
    echo "${VERSION_CONTROL_COMMAND} push origin master"
    ${VERSION_CONTROL_COMMAND} push origin master
fi

echo "================================================================================="
echo "Initial setup (requires user entering password -> invoke manually from command line)"
echo "\$ cap deploy:setup"
echo ""
echo " Check settings from command line:"
echo "\$ cap deploy:check"
echo ""
echo "# The following dependencies failed. Please check them and try again:"
echo "--> You do not have permissions to write to '/var/www/demo'. (testserver)"
echo "--> You do not have permissions to write to '/var/www/demo/releases'. (testserver)"
echo ""
echo "OK, changing owner permissions of /var/www/demo..."
echo "guest\$ sudo chown -R www-data.www-data /var/www/demo"
echo ""
echo "\$ cap deploy:check"
echo ""
echo "  * executing `deploy:check'"
echo "  * executing \"test -d /var/www/demo/releases\""
echo "    servers: [\"testserver\"]"
echo "    [testserver] executing command"
echo "    command finished"
echo "  * executing \"test -w /var/www/demo\""
echo "    servers: [\"testserver\"]"
echo "    [testserver] executing command"
echo "    command finished"
echo "  * executing \"test -w /var/www/demo/releases\""
echo "    servers: [\"testserver\"]"
echo "    [testserver] executing command"
echo "    command finished"
echo "  * executing \"which hg\""
echo "    servers: [\"testserver\"]"
echo "    [testserver] executing command"
echo "    command finished"
echo "You appear to have all necessary dependencies installed"
echo ""
echo "Works :-)"
echo ""
echo "We can deploy using the command"
echo ""
echo "# cap deploy:migrations"
echo ""

echo "Done."