#!/bin/sh

# Put this file in the base folder of
# the source tree.  Search functions
# do not look outside of the directory
# this script is run from.


set -e

arg1=$1 # source file name including dot file extention e.g. "test.cc"
arg2=$2 # argument to program # DEPRECATED - use "run.sh" config file

sourceFile=${arg1}
exe=${arg1%.*} # executable file to build same as source without file extention e.g. "test"

# -----------------------
###
##### CONFIG OPTIONS
###
# -----------------------



# DEFAULTS
GUIdebug=true
useAltScrBuff=false

# SEARCH
# searchMode can be chanaged by entering the mode e.g. REGEX at the search prompt
searchMode="AND"
#searchMode="OR"
#searchMode="REGEX"
# comma seperated list of file extensions to exclude from searches
fileTypeExcludes="o,a,kernel,iso"

# TOOLCHAIN
editor="nano"
debuggerConsole="gdb"
debuggerGUI="gdbgui"
debugger=$debuggerConsole
hexeditor="hexcurse"


# COMPILER CONFIG
# additional include directories
addIncludes='/home/${USER}/libs/'


# source file suffixes
csource="*.c"
cppsource="*.cc"
cppsource2="*.cpp"
asm="*.S"
header="*.h"
scripts="*.sh"
makefile="make.config"



# -----------------------
###
##### END CONFIG OPTIONS
###
# -----------------------

# use the alternate screen buffer (output lost upon exiting devenv)
# set with useAltScrBuff options

if [ "$useAltScrBuff" = "true" ];
then
    tput smcup
fi


# script colors
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

#  black
#  red
#  green
#  yellow
#  blue
#  magenta
#  cyan
#  white
#  reset

# quick edit filename
lastEditedFile=$1
lastHexeditedfile=''





echo "${green}+----------------------+"
        echo "| Lazy Build Env v0.02 |"
        echo "+----------------------+${reset}"



regex_grep(){
    echo "${yellow}Searching source files for ${cyan}${searchString}${yellow}${reset}\n"
    echo "${cyan}$(grep --exclude=*.["$fileTypeExcludes"] -ERnli "$searchString")${reset}\n"
    echo "${cyan}$(grep --exclude=*.["$fileTypeExcludes"] -ERni "$searchString" | wc -l) ${reset}results in ${cyan}$(grep --exclude=*.["$fileTypeExcludes"] -ERnli "$searchString" | wc -l) ${reset}files\n"
}



check_file_exists(){
    set +e

    local filename=$1

    path=$(find -type f -name $filename)

    if [ -z "$path" ];
    then
        printf "File: ${red}${filename}${reset} does not exist. Create it?"
        read input
        case $input in
          [yY])
            touch $filename
          ;;

          [nN])
          ;;
        esac
    fi
    path=$(find -type f -name $filename)

    set -e
}



create_build_script(){
    set +e

    # create a default build.sh file
    output="build.sh"
    printf '%s\n' \
           "#!/bin/sh" \
           "" \
           "compiler=\"g++\"" \
           "compilerArgs=\"-g\"" \
           "includePath=\"${addIncludes}\"" \
           "sourceFiles=\"${sourceFile}\"" \
           "outFile=\"${exe}\"" \
           "libs=\"\"" \
           "CFLAGS=\"\"" \
           "" \
           "for lib in \$libs" \
           "do" \
           "  linkLibs=\"\${linkLibs} -l\${lib}\"" \
           "done" \
           "" \
           "compileCommand=\"" \
           "time \\" \
           "\${compiler} \\" \
           "\${compilerArgs} \\" \
           "-I\${includePath} \\" \
           "\${sourceFiles} \\" \
           "-o \${outFile} \\" \
           "\${linkLibs} \\" \
           "\${CFLAGS} \\" \
           "\"" \
           "" \
           "" \
           "echo \$compileCommand" \
           "" \
           "echo \"Compiling...\"" \
           "echo" \
           "" \
           "eval  \$compileCommand" \
    >> "$output"

    set -e
}



create_run_script(){
    set +e

    output="run.sh"
    printf '%s\n' \
           "#!/bin/sh" \
           "" \
           "./${exe}" \
    >> "$output"

    set -e
}



create_debug_script(){
    set +e

    output="debug.sh"
    printf '%s\n' \
           "#!/bin/sh" \
           "" \
           "${debugger} -f ${exe}" \
    >> "$output"

    set -e
}



project_configure(){
    set +e

    if [ ! -f "./build.sh" ];
    then
        create_build_script
    fi

    if [ ! -f "./run.sh" ];
    then
        create_run_script
    fi

    if [ ! -f "./debug.sh" ];
    then
        create_debug_script
    fi


    $editor build.sh
    $editor run.sh
    $editor debug.sh

    set -e
}



project_list(){
    set +e

    echo "\n${green}Project root: ${reset}"
    pwd

    echo "\n${green}C source: ${reset}\n"
    find -name "$csource"

    echo "\n${green}C++ source: ${reset}\n"
    find -name "$cppsource"
    find -name "$cppsource2"

    echo "\n${green}C headers: ${reset}\n"
    find -name "$header"

    echo "\n${green}Assembly:  ${reset}\n"
    find -name "$asm"

    echo "\n${green}Shell Scripts: ${reset}\n"
    find -name "$scripts"

    echo "\n${green}Make files: ${reset}\n"
    find -name "Makefile" -o -name "$makefile"

    set -e
}


project_search(){
    set +e

    if [ "$searchMode" = "AND" ];
    then
        echo "${yellow}Search Mode: ${reset}${green}[AND]${reset} - [OR] - [REGEX]"
    elif [ "$searchMode" = "OR" ];
    then
        echo "${yellow}Search Mode: ${reset}[AND] - ${green}[OR]${reset} - [REGEX]"
    elif [ "$searchMode" = "REGEX" ];
    then
        echo "${yellow}Search Mode: ${reset}[AND] - [OR] - ${green}[REGEX]${reset}"
    fi



    echo "${yellow}Search string(s) seperated by spaces: ${reset}"
    read searchStrings
    if [ "$searchStrings" = "AND" ];
    then
        searchMode="AND"
        project_search
        return
    elif [ "$searchStrings" = "OR" ];
    then
        searchMode="OR"
        project_search
        return
    elif [ "$searchStrings" = "REGEX" ];
    then
        searchMode="REGEX"
        project_search
        return
    elif [ -z "$searchStrings" ];
    then
        echo "${red}No search string provided${reset}"
        return
    fi

    case $searchMode in
      OR)
        for searchString in $searchStrings
        do
            regex_grep
        done
      ;;
      AND)
          searchString=$(echo $searchStrings | sed -r 's/[ ]+/|/g')
          regex_grep
      ;;
      REGEX)
          searchString=$searchStrings
          regex_grep
    esac

    set -e
}


project_build(){
    set +e

    if [ ! -f "./build.sh" ];
    then
        echo "No ${red}build${reset} file found.  Do ${red}[C]${reset}onfigure to create one"
    else
        bash build.sh
    fi

    set -e
}



project_debug(){
    set +e


    if [ ! -f "./debug.sh" ];
    then
        echo "No ${red}debug.sh${reset} file found.  Do ${red}[C]${reset}onfigure to create one"
    else
        sh debug.sh
    fi


    set -e
}



project_debug_gui(){
    set +e

    command -v $debuggerGUI -r ${exe}
    retval=$?
    if [ "$retval" -gt 0 ];
    then
      echo "${red}Failed to open GUI debug interface, using command line debug${reset}"
      project_debug
    fi

    set -e
}



project_valgrind(){
    set +e

    local file=$1

    valgrind --leak-check=full ./$file

}


project_run(){
    set +e

    if [ ! -f "./run.sh" ];
    then
        echo "No ${red}run.sh${reset} file found.  Do ${red}[C]${reset}onfigure to create one"
    else
        sh run.sh
    fi

    set -e
}



project_edit(){
    set +e

    local opts=$1

    echo "${red}[L]${yellow}ast (${cyan}${lastEditedFile}${yellow}) - Enter filename: ${reset}"
    read filename


    if [ -z "$filename" ] && [ -z "$lastEditedFile" ];
    then
        echo "No filename provided"
    elif [ "$filename" = "l" ];
    then
        path=$(find -type f -name $lastEditedFile)
        check_file_exists $path
        $editor $opts $path
        unset path
    elif [ -z "$filename" ];
    then
        check_file_exists $lastEditedFile
        $editor $opts $path
        unset path
    else
        check_file_exists $filename
        $editor $opts $path
        lastEditedFile=$filename
        unset path
    fi

    set -e
}



project_hexedit(){
    set +e

    if [ -z "$hexeditor" ];
    then
        echo
        echo "${red}No hexeditor configured!${reset}"
        echo
        return
    fi

    echo "${red}[L]${yellow}ast (${cyan}${lastHexEditedFile}${yellow}) - Enter filename: ${reset}"
    read filename

    if [ -z "$filename" ] && [ -z "$lastHexEditedFile" ];
    then
    echo "No filename provided"
    elif [ "$filename" = "l" ];
    then
        path=$(find -type f -name $lastHexEditedFile)
        echo "Opening last file: $path"
        $hexeditor $path
    elif [ -z "$filename" ];
    then
        path=$(find -type f -name $lastHexEditedFile)
        echo "Opening last file: $path"
        $hexeditor $path
    else
        path=$(find -type f -name $filename)
        echo "Opening file: $path"
        $hexeditor $path
        lastHexEditedFile=$filename
    fi

    set -e
}




hexedit(){
    set +e

    file="buffer.bin"
    $hexeditor $file

    set -e
}





spawn_shell(){
    set +e

    export PS1="${cyan}$USER${yellow}@${cyan}DEVENV: ${reset}"
    sh

    set -e
}




project_exit(){
    # do cleanup

    # switch back to primary screen buffer
    if [ "$useAltScrBuff" = "true" ];
    then
        echo "tput rmcup"
        tput rmcup
    fi

    exit
}



########################
#    main menu loop    #
########################

while :
do

echo  "${cyan}--------------------------------------------${reset}"
echo "${yellow}$(pwd)${reset}"

echo "\
${red}[L]${reset}ist    \
${red}[S]${reset}earch      \
${red}[E]${reset}dit"

echo "\
${red}[B]${reset}uild   \
${red}[C]${reset}onfigure   \
${red}[~]${reset}Shell"

echo "\
${red}[D]${reset}ebug   \
${red}[V]${reset}algrind    \
${red}[H]${reset}exEdit   \
${red}[R]${reset}un"
echo  "${cyan}--------------------------------------------${reset}"


read input

case $input in

  [lL])
    project_list
  ;;

  [sS])
    project_search
  ;;

  [eE])
    project_edit
  ;;

  [eE][rR])
    project_edit "-v"
  ;;

  [bB])
    project_build
  ;;

  [cC])
    project_configure
  ;;

  [dD])
    if [ "$GUIdebug" = "true" ];
    then
      project_debug_gui
    else
      project_debug
    fi
  ;;

  [vV])
    project_valgrind ${exe}
  ;;

  [hH])
    project_hexedit
  ;;

  [rR])
    project_run ${exe}
  ;;

  [~])
    spawn_shell
  ;;

  [xX])
    project_exit
  ;;

esac

done
