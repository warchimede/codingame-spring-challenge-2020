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
- the pellet chooses the pac instead of th epac choosing
### Regular pellet in sight
- get the closest unless last position

---> ne pas target les mêmes grosses pillules
---> changer le calcul de pillule la plus proche