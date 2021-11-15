# portal-config-loc
portal configuration and docker-compose to start at local to help service developers and UI developers.

This repository contains several folders configurations to start the light-portal services locally for testing and debugging. Each folder will have a README.md to guide users how to start.

### Kafka

The light-portal depends on Kafka and confluent schema registry. To start the confluent platform, you can checkout the kafka-sidecar and start the docker-compose in that repository. The following is the first step before going into any sub folder in the portal-config-loc. 

```
cd ~/networknt
cd kafka-sidecar
docker-compose up
```

After the Kafka cluster is up and running, we need to create several topics. 

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
# light-scheduler topics
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic light-scheduler --config retention.ms=-1
docker-compose exec broker kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --replication-factor 1 --partitions 3 --topic controller-health-check

```

### light-scheduler

Note: If you only work on the portal components, you don't need to start light-scheduler.

You only need to start the light-scheduler if you want to use the light-controller. You can start three instances with the docker-compose in light-scheduler repository. If light-scheduler is not in your networknt workspace, check it out first.

```
cd ~/networknt
cd light-scheduler
docker-compose up
```

### light-controller

Note: If you only work on the portal components, you don't need to start light-controller.

You only need to start the light-controller if you are about to start some real APIs that register to the controller. If light-controller is not in your networknt workspace, check it out first. 

```
cd ~/networknt
cd light-controller
docker-compose up
```

### light-portal


