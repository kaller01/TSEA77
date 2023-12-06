## Köra simuleringen
När man ska köra simuleringen så ska man klicka i PIN C i bit 0, då är knappen nedtryckt. Om man sedan sätter en breakpoint längst ned vid ”ret” så kan man använda F5 för att se portarna räkna upp. Detta sätt att kolla på simuleringen är väldigt effektivt då man ser det man vill.

## Känner av en annan insignal (annan pinne, annan port)
För att byta port och pinne behöver man ändra ett par saker. Dels att just ändra pin och port, tex

sbic PINB ,2

Så har man ändrat till port B och pin 2. Men man måste även se till att ändra så att denna port tar emot input i INIT rutinen. Detta genom ”out DDRB, r16”.

## Skickar ut data på övre porthalvan (B7-B4) istället
Det första steget är att aktivera output på B7-B4

ldi r16 , $F0

out DDRC , r16

Dock kommer den fortfarande försöka skicka ut på B3-B0, därav at man skickar ut hela num på B, enklaste sättet är att göra en ”swap num” innan ”out” och efter för att all logik fortfarande ska fungera. Detta göra innan outputen så flyttas den låga delen till den höga delen, och när det är dags att kolla om den är 10 så har man redan swapat tillbaka. Påverkar endast outputen.

## Direkt utför additionen på r20:s höga nibble
Istället för att göra ”inc num” efter swappen så kan man lägga till 16 på den höga nibblen innan swappen. Detta gör man enklast med ”subi num, -16”. Detta för att 16 är 00010000 i bytes, alltså ökar den med 1 på hög nibble.

## Skickar ut data på en annan port
Det första steget är att aktivera output på en ports höga nibble. Tex port D. Sedan ändrar man i ”loop” så att den även skickar ut i port D.

## Räknar till annat slutvärde
Denna är väldigt enkel. Det räcker att byta ut 10 med ett annat värde, dock behöver man tänka på att det är mindre än 16 så det får plats i en nibble. Tex 13. Då kommer den räkna upp till 13.

## Räknar baklänges
Nu kan det bli lite knasigt om man behåller swap, då om num är noll och man börjar räkna neråt så kommer den högre nibbeln bli påverkade medans vi vill swappa och bara använda den lägre delen. Det kommer data i båda nibbleserna, vilket blir helt fel då vi bara vill använda en nibbel. Det enklaste är att ta bort alla swaps och anpassa koden efter att jobba i den högre nibblen.

Istället för att räkna till 10 får man räkna till 160, då kan man ta bort alla swaps. Att sedan verifiera att det körs som det ska är viktigt. Nu har man kommit iväg från problemen att räkna baklänges, nu gör man all logik med den höga delen. Nu när man tar bort 16 från 0 kommer man få 1110 000, vilket kommer fungera bra.

                                                                                                                                                                               