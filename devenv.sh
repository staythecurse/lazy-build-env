#!/bin/sh

# Put this file in the base folder of
# the source tree.  Search functions
# do not look outside of the directory
# this script is run from.

set -e

arg1=$1 # source file name
arg2=$2 # argument to program (if it compiles to a single executable)

# config options
hexeditor="hexcurse"

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

# source file suffixes
csource="*.c"
cppsource="*.cc"
asm="*.S"
header="*.h"
scripts="*.sh"
makefile="make.config"

echo "${green}+----------------------+"
        echo "| Lazy Build Env v0.01 |"
        echo "+----------------------+${reset}"

project_list(){
    set +e

    echo "\n${green}C source: ${reset}\n"
    find -name "$csource"

    echo "\n${green}C++ source: ${reset}\n"
    find -name "$cppsource"

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

    file=$1

    echo "File is - $file -"
    echo

    if [ -z "$file" ];
    then
        echo "${red}No C++ file to build${reset}"
        echo "Enter filename: "
        read file
        project_build $file
    else
        # compile with debug symbols
        gcc -v -o0 -g -lstdc++ "${file}" -o "${file%.*}"
        # no debug symbols -o3 optimization
#        gcc -v -o3 -lstdc++ "${file}" -o "${file%.*}"
    fi

    set -e
}



project_debug(){
    set +e

    gdb --se ${arg1%.*}

    set -e
}



project_run(){
    set +e

    file=$1
    echo
    echo "Executing: $1"
    echo
    if [ -z "$file" ];
    then
        echo "No file to execute"
        echo "Enter filename: "
        read file
        project_run $file $arg2
    else
        ./$file $arg2
    fi

    set -e
}



project_edit(){
    set +e

    echo "${red}[L]${yellow}ast (${cyan}${lastEditedFile}${yellow}) - Enter filename: ${reset}"
    read filename

    if [ -z $filename ] && [ -z $lastEditedFile ];
    then
    echo "No filename provided"
    elif [ $filename = "l" ];
    then
        path=$(find -type f -name $lastEditedFile)
        echo "Opening last file: $path"
        nano $path
    elif [ -z $filename ];
    then
        path=$(find -type f -name $lastEditedFile)
        echo "Opening last file: $path"
        nano $path
    else
        path=$(find -type f -name $filename)
        echo "Opening file: $path"
        nano $path
        lastEditedFile=$filename
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
    elif [ $filename = "l" ];
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




########################
#    main menu loop    #
########################

while :
do

echo "${cyan}-----------------------------${reset}"
#echo "${cyan}SOURCES"
echo "\
${red}[L]${reset}ist sources - \
${red}[S]${reset}earch sources - \
${red}[E]${reset}dit sources"
echo "${cyan}-----------------------------${reset}"
#echo "${cyan}BUILD"
echo "\
${red}[B]${reset}uild"
echo "${cyan}-----------------------------${reset}"
#echo "${cyan}DEBUG"
echo "\
${red}[D]${reset}ebug - \
${red}[H]${reset}exEdit -\
${red}[R]${reset}un"
echo "${cyan}-----------------------------${reset}"
echo "\
e${red}[X]${reset}it"

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

  [bB])
    project_build $arg1
  ;;

  [dD])
    project_debug
  ;;

  [hH])
    project_hexedit
  ;;

  [rR])
    project_run ${arg1%.*}
  ;;

  [xX])
  exit
  ;;

esac

done
