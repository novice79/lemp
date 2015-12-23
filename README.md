# lemp
for docker hub auto build
# build locally
docker build -t novice/lemp .
# run it like this
docker run -p 222:22 -p 80:80 -p 3306:3306 -d --name fg -t novice/lemp