# portal-config-loc
portal configuration and docker-compose to start light-portal services at local to help service developers and UI developers. For pure UI developers, he/she can use the https://localhost:3000 to connect to the dev portal server.

This repository contains several folders configurations to start the light-portal services locally for testing and debugging. Each folder will have a README.md to guide users how to start.

### Confluent

For easy debugging with host network and standalone services in IDE, we will start the Kafka with the confluent command line.


To install the confluent local, go to https://www.confluent.io/installation/ to download the tar file. Once it is downloaded, move the file to the ~/tool folder and unzip it.

```
tar xzf confluent-7.7.0.tar
```

Update the export in .profile for the new folder of of confluent version. 

```
export CONFLUENT_HOME=~/tool/confluent-7.7.0
export PATH=$PATH:$CONFLUENT_HOME/bin
export CONFLUENT_CURRENT=/opt/confluent
```

To start the services.

```
confluent local services start
```

By default the confluent log will be in the /tmp folder. We want to make sure that the log can survive desktop restart. Due to permission issue, you might need to create /opt/confluent folder and change owner to your user. 

```
cd ~/opt
sudo mkdir confluent
sudo chown steve:steve confluent
```

Now, let's create topics.

```
#### Block Chain
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic taiji --config retention.ms=-1
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic snapshot --config cleanup.policy=compact
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic event --config retention.ms=-1
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic notification --config retention.ms=-1
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic symbol-token --config cleanup.policy=compact

#### Light Portal
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-event --config retention.ms=-1
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-nonce --config cleanup.policy=compact
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-notification --config retention.ms=-1

# city an map should be removed as sync between nodes are not working in a timely fasion.
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-city --config cleanup.policy=compact
# kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-map --config cleanup.policy=compact

kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-userid --config cleanup.policy=compact
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-taiji --config cleanup.policy=compact

kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-reference --config cleanup.policy=compact
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic light-scheduler --config cleanup.policy=compact
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic controller-health-check


# kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic portal-log --config retention.ms=-1

```

Above steps are one time process after installation. For daily restarting, you can just run the following command from the confluent-x.x.x/bin folder.

```
confluent local services start
```

### Kafka Docker

This is another way to start the confluent with docker-compose for local demo only. For development and debugging, use the confluent local instead.


The light-portal depends on Kafka and confluent schema registry. To start the confluent platform, you can checkout the kafka-sidecar and start the docker-compose in that repository. The following is the first step before going into any sub folder in the portal-config-loc.

```
cd ~/networknt
cd kafka-sidecar
docker-compose down
docker-compose up
```

After the Kafka cluster is up and running, we need to create several topics. Open another terminal and go to the `~/networknt/kafka-sidecar` folder and paste the following command lines.

```
# blockchain topics
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic taiji --config retention.ms=-1
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic snapshot --config cleanup.policy=compact
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic event --config retention.ms=-1
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic notification --config retention.ms=-1
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic symbol-token --config cleanup.policy=compact
# light-portal topics
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic portal-event --config retention.ms=-1
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic portal-nonce --config cleanup.policy=compact
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic portal-notification --config retention.ms=-1
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic portal-userid --config cleanup.policy=compact
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic portal-taiji --config cleanup.policy=compact
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic portal-reference --config cleanup.policy=compact

# light-scheduler topics
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic light-scheduler --config retention.ms=-1
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic controller-health-check

```

You can check your topics from the control center at the following url.

http://localhost:9021/


### light-scheduler

You only need to start the light-scheduler if you want to use the light-controller. You can start three instances with the docker-compose in light-scheduler subfolder from portal-config-loc folder.

Checkout the lightapi/portal-config-loc if it is not checked out yet.

```
cd ~/lightapi/portal-config-loc/light-scheduler
docker compose down
docker compose up
```

### light-portal

Checkout the lightapi/portal-config-loc and download the user, market and ref query jars.

```
cd ~/lightapi/portal-config-loc/light-portal/hybrid-query/service
rm *
curl -k https://s01.oss.sonatype.org/content/repositories/snapshots/net/lightapi/market-query/2.0.33-SNAPSHOT/market-query-2.0.33-20211201.230417-18.jar -o market-query.jar
curl -k https://s01.oss.sonatype.org/content/repositories/snapshots/net/lightapi/user-query/2.0.33-SNAPSHOT/user-query-2.0.33-20211125.173522-16.jar -o user-query.jar
curl -k https://s01.oss.sonatype.org/content/repositories/snapshots/net/lightapi/ref-query/2.0.33-SNAPSHOT/ref-query-2.0.33-20211125.173542-8.jar -o ref-query.jar

```

Download command side jar files.

```
cd ~/lightapi/portal-config-loc/light-portal/hybrid-command/service
rm *
curl -k https://s01.oss.sonatype.org/content/repositories/snapshots/net/lightapi/user-command/2.0.33-SNAPSHOT/user-command-2.0.33-20211125.173509-15.jar -o user-command.jar
curl -k https://s01.oss.sonatype.org/content/repositories/snapshots/net/lightapi/market-command/2.0.33-SNAPSHOT/market-command-2.0.33-20211125.173444-12.jar -o market-command.jar
curl -k https://s01.oss.sonatype.org/content/repositories/snapshots/net/lightapi/ref-command/2.0.33-SNAPSHOT/ref-command-2.0.33-20211125.173532-8.jar -o ref-command.jar
```

start the light-portal services with the following docker-compose.

```
cd ~/lightapi/portal-config-loc/light-portal
docker compose down
docker compose up
```
Once the services are up and running, we need to import the events to create users and clients etc. The imported events will create an admin user stevehu@gmail.com and this user will be able to create other necessary entities to bootstrap the application.

To run the event-importer, we need to download the jar. Once you have the jar file in the portal-config-loc/light-portal folder, you can use it to import the events.json file.

```
cd ~/lightapi/portal-config-loc/light-portal
curl -k https://s01.oss.sonatype.org/content/repositories/snapshots/net/lightapi/event-importer/2.0.33-SNAPSHOT/event-importer-2.0.33-20211201.192409-11.jar -o event-importer.jar
./importer.sh events.json
```

### light-controller

You only need to start the light-controller if you are about to start some real APIs that register to the controller. If light-controller is not in your networknt workspace, check it out first.

```
cd ~/lightapi/portal-config-loc/light-controller
docker compose down
docker compose up
```

### oauth-kafka

Start the OAuth 2.0 provider.

```
cd ~/lightapi/portal-config-loc/oauth-kafka
docker compose down
docker compose up
```

### config-server

Start the light-config-server

```
cd ~/lightapi/portal-config-loc/config-server
docker compose down
docker compose up
```

### light-gateway

The login page for oauth-kafka service is served by the light-gateway with a domain name `devsignin.lightapi.net` and it must be added to the /etc/hosts (for windows: C:\Windows\System32\drivers\etc) file. On my computer the following entry is added. 

```
192.168.5.10   local.lightapi.net devsignin.lightapi.net devoauth.lightapi.net local.taiji.io devfaucet.taiji.io
```

Based on your desktop IP, you need to change the IP address.


Make sure that you have the bootstrap token in the .profile as environment variable to support the integration. Also, if you want to use google, facebook and github for authentication, you need to have the client secret for them in the .profile file.

```
export STATELESS_AUTH_BOOTSTRAP_TOKEN=eyJraWQiOiIxMDAiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJ1cm46Y29tOm5ldHdvcmtudDpvYXV0aDI6djEiLCJhdWQiOiJ1cm46Y29tLm5ldHdvcmtudCIsImV4cCI6MTkxMjk0MzAzMiwianRpIjoia3NPRHl0MlFVU25CY0NublpOMmZSZyIsImlhdCI6MTU5NzU4MzAzMiwibmJmIjoxNTk3NTgyOTEyLCJ2ZXJzaW9uIjoiMS4wIiwiY2xpZW50X2lkIjoiZjdkNDIzNDgtYzY0Ny00ZWZiLWE1MmQtNGM1Nzg3NDIxZTczIiwic2NvcGUiOlsicG9ydGFsLnIiLCJwb3J0YWwudyJdfQ.uCfoIZMx5xhlHvLAnmgkyuSnTGm0pTEosZOgFdGf946XeAxzULQk6mwHz0wu0oNL_L0hT1uOsgANfNpVmS44nbedkqELgHAnJpHf4IP7EStHk3o99MPZSVLufKvKmbP6-G0Th-1a8wK5XkX1_9WIhHAmxr-D23VQpvJq_XOKH24Ik06qSVUj-B3YAHrqlNIk4b-WqUYhUkluOYvI4mvCwB-xi5-Nioqa6JqpXO9fv7bb9xQzKX_3MsuEYT-LO8vquNtKPJLbz42vP1A5calbyBNZ4pnKgJyjH9_TFMywNZ-C7y2ZlhNR5_F-MKKysVkOC25TJmV49om_kb2lnoEDKg
```

Now, let's start the light-router and other services.

```
cd ~/lightapi/portal-config-loc/light-gateway
docker compose up

```

To allow the access to the port 443 on the browser and redirect to 8443 listening with the light-router. We need to update the iptables rule.

```
sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -o lo -j REDIRECT --to-port 8443
```

On Windows desktop, maybe we can use 443 as the port to start the light-router in the docker-compose. However, the idea is not tested yet. If you are using Windows, try the following command.

```
docker compose -f docker-compose-windows.yml up
```

### Portal View

Start the portal view in Nodejs to UI development.

```
cd networknt
git clone git@github.com:networknt/portal-view.git
cd ~/networknt/portal-view
yarn install
HTTPS=true yarn start

```

click the user profile icon on the top right corner to login with

```
stevehu@gmail.com
123456
```
