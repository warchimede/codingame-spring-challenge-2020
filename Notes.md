# Path Finding

## Priorities
- avoid walls
- get pellets
- don't die
- kill others

## Move Situations
### Collision stuck
- move d'un pas dans une autre direction
- no move si pas possible

### Arrived
#### No pellets
- avance d'un pas dans une direction, pas en arrière sauf si c'est la seule
### High pellet in sight
- go get it unless last position
### Regular pellet in sight
- get the closest unless last position

---> Essayer de gérer les tunnels de la map