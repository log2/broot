#WARNING: This script is NOT meant for normal installation, it's dedicated
# to the compilation of all supported targets.
# This is a long process and it involves specialized toolchains.
# For usual compilation do
#     cargo build --release
# or read all possible installation solutions on
# https://dystroy.org/broot/documentation/installation/

H1="\n\e[30;104;1m\e[2K\n\e[A" # style first header
H2="\n\e[30;104m\e[1K\n\e[A" # style second header
EH="\e[00m\n\e[2K" # end header
NAME=broot
version=$(./version.sh)

echo -e "${H1}Compilation of all targets for $NAME $version${EH}"
 
# clean previous build
rm -rf build
mkdir build
echo "   build cleaned"
 
# build the default linux version (with clipboard support)
# recent glibc
echo -e "${H2}Compiling the standard linux version${EH}"
cargo build --release --features "clipboard"
strip "target/release/$NAME"
mkdir build/x86_64-linux/
cp "target/release/$NAME" build/x86_64-linux/

# build, find, and copy the completion scripts
# (they're built as part of the normal compilation)
echo -e "${H2}building and copying completion scripts${EH}"
mkdir build/completion
cp "$(broot -c ":gi;release;:focus;broot.bash;:parent;:pp" target)/"* build/completion
echo "   Done"

# copy the default conf
echo -e "${H2}copying default configuration${EH}"
cp resources/default-conf.hjson build
echo "   Done"
 
# add the resource (the icons font)
echo -e "${H2}copying vscode-icon font${EH}"
mkdir build/resources
cp resources/icons/vscode/vscode.ttf build/resources
echo "the font file comes from https://github.com/vscode-icons/vscode-icons/ and is licensed as MIT" > build/resources/README.md
echo "   Done"

# build versions for other platforms using cargo cross
cross_build() {
    target_name="$1"
    target="$2"
    features="$3"
    echo -e "${H2}Compiling the $target_name version (target=$target, features='$features')${EH}"
    if [[ -n $features ]]
    then
        cross build --target "$target" --release --features "$features"
    else
        cross build --target "$target" --release
    fi
    mkdir "build/$target"
    if [[ $target_name == 'Windows' ]]
    then
        exec="$NAME.exe"
    else
        exec="$NAME"
    fi
    cp "target/$target/release/$exec" "build/$target/"
}
cross_build "Android" "aarch64-linux-android" "clipboard"
cross_build "Linux GLIBC" "x86_64-unknown-linux-gnu" ""
cross_build "MUSL" "x86_64-unknown-linux-musl" ""
cross_build "Raspberry 32" "armv7-unknown-linux-gnueabihf" ""
cross_build "Windows" "x86_64-pc-windows-gnu" "clipboard"

# add a summary of content
echo '
This archive contains pre-compiled binaries:

x86_64-linux/broot : standard Linux, clipboard support, most optimized
aarch64-linux-android/broot : Android, clipboard support
x86_64-unknown-linux-gnu : Linux/glibc, no clipboard support, compatible with older GLIBC
x86_64-unknown-linux-musl : Linux/musl, no clipboard support
armv7-unknown-linux-gnueabihf : Raspberry | no clipboard support
x86_64-pc-windows-gnu : Windows 10+, clipboard support

For more information, or if you prefer to compile yourself, see https://dystroy.org/broot/install
' > build/install.md

echo -e "${H1}FINISHED${EH}"
