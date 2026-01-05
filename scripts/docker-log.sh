#!/bin/bash
rm query1.txt
rm query2.txt
rm query3.txt
rm command.txt
rm oauth.txt
rm postgres.txt
rm reference.txt
rm gateway.txt
rm broker.txt
rm connect.txt
rm config.txt

docker logs hybrid-query1 > query1.txt
docker logs hybrid-query2 > query2.txt
docker logs hybrid-query3 > query3.txt
docker logs hybrid-command > command.txt
docker logs oauth-kafka > oauth.txt
docker logs postgres > postgres.txt
docker logs reference > reference.txt
docker logs light-gateway > gateway.txt
docker logs broker > broker.txt
docker logs connect > connect.txt
docker logs config-server > config.txt

