DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

echo 

# check podspec
pod lib lint

# push trunk podspec
pod trunk push *.podspec



