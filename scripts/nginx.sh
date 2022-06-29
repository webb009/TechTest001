sudo apt install docker-ce -y
sudo usermod -a -G docker $USER
sudo systemctl enable docker
sudo systemctl restart docker
sudo docker run --name docker-nginx -p 80:80 nginx:latest
