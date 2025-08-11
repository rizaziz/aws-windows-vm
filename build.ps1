$image_name = "dev"
& docker rm $image_name 2>$null
docker build -t $image_name .
docker run --name $image_name $image_name
docker export $image_name -o "$image_name.tar"

wsl --unregister $image_name

wsl --import $image_name C:\Distros dev.tar

wsl --set-default $image_name

rm "$image_name.tar"
