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
debugGUI=false
useAltScrBuff=false


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

if [ $useAltScrBuff = "true" ];
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
        echo "| Lazy Build Env v0.01 |"
        echo "+----------------------+${reset}"




check_file_exists(){
    set +e

    local filename=$1

    path=$(find -type f -name $filename)

    if [ -z $path ];
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
           "#!/bin/bash" \
           "" \
           "compiler=\"g++\"" \
           "compilerArgs=\"-g\"" \
           "includePath=\"${addIncludes}\"" \
           "sourceFiles=\"${sourceFile}\"" \
           "outFile=\"${exe}\"" \
           "linkLibs=\"\"" \
           "CFLAGS=\"\"" \
           "" \
           "echo \"Compiling...\"" \
           "" \
           "time \\" \
           "\${compiler} \\" \
           "\${compilerArgs} \\" \
           "-I\${includePath} \\" \
           "\${sourceFiles} \\" \
           "-o \${outFile} \\" \
           "#-l\${linkLibs} \\" \
           "#\${CFLAGS} \\" \
    >> "$output"

    set -e
}



create_run_script(){
    set +e

    output="run.sh"
    printf '%s\n' \
           "#!/bin/bash" \
           "" \
           "./${exe}" \
    >> "$output"

    set -e
}



create_debug_script(){
    set +e

    output="debug.sh"
    printf '%s\n' \
           "#!/bin/bash" \
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

    echo "\n${green}Build Scripts: ${reset}\n"
    find -name "$scripts"

    echo "\n${green}Make files: ${reset}\n"
    find -name "Makefile" -o -name "$makefile"

    set -e
}


project_search(){
    set +e

    echo "${yellow}Search string: ${reset}"
    read searchString
    echo
    echo "${yellow}Searching source files for ${cyan}${searchString}${yellow}${reset}\n"
    echo "${cyan}$(grep --exclude={\*.o,\*.a,\*.kernel,\*.iso} -Rnli "$searchString")${reset}\n"
    echo "${cyan}$(grep --exclude={\*.o,\*.a,\*.kernel,\*.iso} -Rni "$searchString" | wc -l) ${reset}results in ${cyan}$(grep --exclude={\*.o,\*.a,\*.kernel,\*.iso} -Rnli "$searchString" | wc -l) ${reset}files\n"

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
        bash debug.sh
    fi


    set -e
}



project_debug_gui(){
    set +e

    $debuggerGUI -r ${exe}

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
        bash run.sh
    fi

    set -e
}



project_edit(){
    set +e

    local opts=$1

    echo "${red}[L]${yellow}ast (${cyan}${lastEditedFile}${yellow}) - Enter filename: ${reset}"
    read filename


    if [ -z $filename ] && [ -z $lastEditedFile ];
    then
        echo "No filename provided"
    elif [ "$filename" = "l" ];
    then
        path=$(find -type f -name $lastEditedFile)
        check_file_exists $path
        echo "ONE Opening last file: $path"
        $editor $opts $path
        unset path
    elif [ -z $filename ];
    then
#        path=$(find -type f -name $lastEditedFile)
        check_file_exists $lastEditedFile
        echo "TWO Opening last file: $path"
        $editor $opts $path
        unset path
    else
#        path=$(find -type f -name $filename)
        check_file_exists $filename
        echo "THREE Opening file: $path"
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

    if [ -z $filename ] && [ -z $lastHexEditedFile ];
    then
    echo "No filename provided"
    elif [ "$filename" = "l" ];
    then
        path=$(find -type f -name $lastHexEditedFile)
        echo "Opening last file: $path"
        $hexeditor $path
    elif [ -z $filename ];
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

    bash

    set -e
}




project_exit(){
    # do cleanup

    # switch back to primary screen buffer
    if [ $useAltScrBuff = "true" ];
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

echo "${cyan}-----------------------------${reset}"
echo "${yellow}Project root: $(pwd)${reset}"
echo "${cyan}-----------------------------${reset}"
#echo "${cyan}SOURCES"

echo "\
${red}[L]${reset}ist sources - \
${red}[S]${reset}earch sources - \
${red}[E]${reset}dit sources"

echo "${cyan}-----------------------------${reset}"
#echo "${cyan}BUILD"

echo "\
${red}[B]${reset}uild - \
${red}[C]${reset}onfigure \
${red}[~]${reset}Shell"

echo "${cyan}-----------------------------${reset}"
#echo "${cyan}DEBUG"

echo "\
${red}[D]${reset}ebug - \
${red}[V]${reset}algrind - \
${red}[H]${reset}exEdit -\
${red}[R]${reset}un"

echo "${cyan}-----------------------------${reset}"

echo "e${red}[X]${reset}it"

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
    if [ $debugGUI = "true" ];
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
