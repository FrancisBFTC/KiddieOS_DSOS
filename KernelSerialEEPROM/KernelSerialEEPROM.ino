#include <EEPROM.h>

#define SIZEMATRIX 37
#define ESC  1
#define TAB  15
#define F3   0x3D
#define F4   0x3E
#define POS_ADDR  1023

int AddrWrite = 0;
int AddrRead  = 0;
//bool F2_Press = false;
//bool F3_Press = false;

char character = 0;
char StopRead = '$';
char matrix[SIZEMATRIX][2] = 
                    {' ', 57, 'a',30,'b',48,'c',46,'d',32,'e',18,'f',33,'g',34,'h',35,'i',23,'j',36,
                     'k',37,'l',38,'m',50,'n',49,'o',24,'p',25,'q',16,'r',19,'s',31,'t',20,
                     'u',22,'v',47,'w',17,'x',45,'y',21,'z',44,'1',2,'2',3,'3',4,'4',5,
                     '5',6,'6',7,'7',8,'8',9,'9',10,'0',11};

                    

void setup() {
  Serial.begin(9600);
  AddrWrite = EEPROM.read(POS_ADDR);
}

void loop() {
  if(Serial.available() > 0){
    character = Serial.read();
      
    switch(character){
      case F3: EEPROM_Write(); break;
      case F4: EEPROM_Read(); break;
      default: break; 
    }

    
  }
  
}

void EEPROM_Write(){
  while(Serial.read() != StopRead){
    character = Serial.read();
    EEPROM.write(AddrWrite, character);
    AddrWrite = AddrWrite + 1;
  }
  EEPROM.write(POS_ADDR, AddrWrite);
}

void EEPROM_Read(){
  while(AddrRead < AddrWrite){
    character = EEPROM.read(AddrRead);
    AddrRead = AddrRead + 1;
    Serial.write(character);
  }
  AddrRead = 0;
  Serial.write(StopRead);
}
