#!/bin/bash
rm query1.txt
rm query2.txt
rm query3.txt
rm query.txt
rm command.txt
rm oauth.txt
rm postgres.txt
rm reference.txt
rm gateway.txt
rm broker.txt
rm connect.txt
rm config.txt
rm controller.txt
rm workflow.txt
rm agent.txt
rm customer-profile.txt
rm offer-decision.txt
rm insurance-claim.txt

docker logs hybrid-query1 > query1.txt
docker logs hybrid-query2 > query2.txt
docker logs hybrid-query3 > query3.txt
docker logs hybrid-query > query.txt
docker logs hybrid-command > command.txt
docker logs light-oauth > oauth.txt
docker logs postgres > postgres.txt
docker logs portal-service > reference.txt
docker logs light-gateway > gateway.txt
docker logs broker > broker.txt
docker logs connect > connect.txt
docker logs config-server > config.txt
docker logs controller > controller.txt
docker logs light-workflow > workflow.txt
docker logs light-agent > agent.txt
docker logs demo-customer-profile-api > customer-profile.txt
docker logs demo-offer-decision-api > offer-decision.txt
docker logs demo-insurance-claim-mcp-server > insurance-claim.txt
