# Instructions

docker-compose up

## Add a meesage to the queue

podman exec -it redis redis-cli LPUSH my_queue "Hello from shell2!

podman exec -it redis redis-cli LRANGE my_queue 0 -1


## Consume the message from the queue

podman exec -it redis redis-cli RPOP my_queue