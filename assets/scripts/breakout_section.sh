#!/bin/bash


function print_help {
    echo "Usage: breakout_section.sh <section-name> [from-file]"
    echo "  from-file defaults to /airtime/install"
    echo "  section is broken out into install_<section-name> in same dir"
    echo "Note: Creates backup of original file with prefix .backup"
}

function add_shebang() {
    if [[ -e $1 ]]; then
        sed -i '1i #!/bin/bash' "$1"
    fi
}

function add_function() {
    echo "Copying function $1 from $2 to $3"
    sed -i '
2a \

3e sed -n "/function '"$1"'.*{$/,/^}[ ^I]*$/ p" '"$2"'
' "$3"
}

if [[ $# < 1 ]]; then
    echo "Incorrect number of arguments."
    print_help
    exit 1
fi

SECTION=$1
INSTALL_FILE=$(realpath ${2:-"/airtime/install"})
NEW_FILE=$(dirname $(realpath $INSTALL_FILE))"/install_$SECTION"

echo "Moving $SECTION section from $INSTALL_FILE to $NEW_FILE"

#Increment counter for multiple backups
i=0
while [[ -e "$INSTALL_FILE.backup$i" ]]; do
    ((i++))
done

echo "New backup will be: $INSTALL_FILE.backup$i"
# Move section to separate file
sed -n -i.backup$i '
/loud \"\\n-*\"$/ {
    N
    /'"$1"'/I {
        :tl; H; n
        /loud \"\\n-*\"$/ {
            x;w '"$NEW_FILE"'
            x;b end
        }
        /loud \"\\n-*\"$/ !{
            b tl
        }
    }
    :end
}
/.*/ p
' $INSTALL_FILE

echo "Adding shebang to new script"
add_shebang $NEW_FILE
echo "adding necessary 'loudCmd' function"
add_function loudCmd "$INSTALL_FILE" "$NEW_FILE"


# vim: tabstop=4 shiftwidth=4 expandtab
