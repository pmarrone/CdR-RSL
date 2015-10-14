/*-----------------------------------------------------
Author:  --<>
Date: 2015-10-08
Description:

-----------------------------------------------------*/
#define RIGHT_ONLY 1
#define LEFT_ONLY 2
#define BOTH 3
#define NONE 4
#define ANALOG_MAX 1023

typedef enum  {
    WHERE_AM_I, 
    PROBABLY_LEFT, 
    PROBABLY_RIGHT, 
    ENGAGING_LEFT,
    ENGAGING_RIGHT,
    RUNNING_ON_THE_LINE
} states;


const int leftSpeed = 11;
const int leftDirection = 9;
const int rightSpeed = 12;
const int rightDirection = 10;
const int sensor4 = 13;
const int sensor2 = 14;
const s16 speed = 1000;
const s16 mediumSpeed = 600;
states state;

double P = 1;
double I = 0.01; 
double D = 1;
u8 status;
u16 rightSensor; 
u16 leftSensor;

u16 onLineThreshold = 50;
void leftWheel(s16 wheelSpeed);
void rightWheel(s16 wheelSpeed);
void wheels(s16 leftWheelSpeed, s16 rightWheelSpeed);
void turnLeft();
void turnRight();
void sharpRight();
void sharpLeft();
void stop();
void fullForward();
void sensorsDebug();
void runningOnTheLine();
void engagingFromRight();
void engagingFromLeft();
void probablyLeft();
void probablyRight();
void whereAmI();
void readSensors();
void stateMachine();

u8 getStatus(u16 leftReading, u16 rightReading) {
    if (leftReading > onLineThreshold  && rightReading > onLineThreshold) {
        return BOTH;
    } else if (leftReading > onLineThreshold) {
        return LEFT_ONLY;
    } else if (rightReading > onLineThreshold) {
        return RIGHT_ONLY;
    } else {
        return NONE;
    }
}

BOOL isOnLine(u16 reading) {
    return reading > onLineThreshold;
}

inline void leftWheel(s16 wheelSpeed) {
    wheelSpeed = -wheelSpeed;
    //CDC.printf("leftWheel called, wheelSpeed: %d\n", wheelSpeed);
    if (wheelSpeed > ANALOG_MAX ) {
       wheelSpeed = ANALOG_MAX;     
    } else if (wheelSpeed < -ANALOG_MAX) {
       wheelSpeed = -ANALOG_MAX; 
    }
    
    if (wheelSpeed >= 0) {
        //CDC.printf("leftDirection: HIGH, leftSpeed: %d\n", wheelSpeed);
        digitalWrite(leftDirection, LOW);
        analogWrite(leftSpeed, wheelSpeed);
    } else {
        digitalWrite(leftDirection, HIGH);
        //CDC.printf("leftDirection: LOW, leftSpeed: %d\n", ANALOG_MAX + wheelSpeed);
        analogWrite(leftSpeed, ANALOG_MAX + wheelSpeed);
    }
}

inline void rightWheel(s16 wheelSpeed) {
    wheelSpeed = -wheelSpeed;
    //CDC.printf("rightWheel called, wheelSpeed: %d\n", wheelSpeed);
    if (wheelSpeed > ANALOG_MAX ) {
       wheelSpeed = ANALOG_MAX;     
    } else if (wheelSpeed < -ANALOG_MAX) {
       wheelSpeed = -ANALOG_MAX; 
    }
    
    if (wheelSpeed >= 0) {
        //CDC.printf("rightDirection: HIGH, rightSpeed: %d\n", wheelSpeed);
        digitalWrite(rightDirection , LOW);
        analogWrite(rightSpeed, wheelSpeed);
    } else {
        //CDC.printf("rightDirection: LOW, rightSpeed: %d\n", ANALOG_MAX + wheelSpeed);
        digitalWrite(rightDirection, HIGH);
        analogWrite(rightSpeed, ANALOG_MAX + wheelSpeed);
    }
}

inline void wheels(s16 leftWheelSpeed, s16 rightWheelSpeed) {
    //CDC.printf("Wheels called: left: %d, right: %d", leftWheelSpeed, rightWheelSpeed);
    leftWheel(leftWheelSpeed);
    rightWheel(rightWheelSpeed);
}

inline void turnRight() {
    wheels(speed, 0);
}

inline  void sharpRight() {
    wheels(speed, -speed);
}

inline void turnLeft() {
    wheels(0, speed);
}

inline void sharpLeft() {
    wheels(-speed, speed);
}

inline void stop() {
    wheels(0, 0);
}

inline void fullForward() {
    wheels(speed, speed);
}

void setup() {
    int i = 0;
    pinMode(leftSpeed, OUTPUT);
    pinMode(leftDirection , OUTPUT);
    pinMode(rightSpeed, OUTPUT);
    pinMode(rightDirection, OUTPUT);
    pinMode(sensor2, INPUT);
    pinMode(sensor4, INPUT);
    
    
    for (i = 0; i < 8; i++) {
        pinMode(i, OUTPUT);
    }
    leftWheel(0);
    rightWheel(0);
    state = WHERE_AM_I;
}



inline void sensorsDebug() {
    int i;
    CDC.printf("Status: %d, State: %d\n", getStatus(leftSensor, rightSensor), state);
    //CDC.printf(",Left: %d, Right: %d", leftSensor, rightSensor);
    
    //CDC.printf("\n");
    for (i = 0; i < 4; i++) {
        if (rightSensor > (i + 1) * 512 / 4) {
            digitalWrite(i, LOW);
        } else {
            digitalWrite(i, HIGH);
        }
    }
    
    for (i = 0; i < 4; i++) {
        if (leftSensor > (i + 1) * 512 / 4) {
            digitalWrite(7 - i, LOW);
        } else {
            digitalWrite(7 - i, HIGH);
        }
    }
}

inline void runningOnTheLine() {
  CDC.printf("We are doing great!");
  fullForward();
  switch (status) {
      case NONE:
          state = WHERE_AM_I;
          break;
      case LEFT_ONLY:
          state = ENGAGING_RIGHT;
          break;
      case RIGHT_ONLY:
          state = ENGAGING_LEFT;
          break;
      case BOTH:
          //We are still doing great :)
          break;
  }
}

inline void engagingFromRight() {
  CDC.printf("Engaging from the right. Turning right slightly...\n");
  turnRight();
  switch (status) {
      case NONE:
          state = PROBABLY_RIGHT;
          break;
      case LEFT_ONLY:
          break;
      case RIGHT_ONLY:
          state = ENGAGING_LEFT;
          break;
      case BOTH:
          state = RUNNING_ON_THE_LINE;
          break;
      
  }
}

inline void engagingFromLeft() {
  CDC.printf("Engaging from the left. Turning slightly...\n");
  turnLeft();
  switch (status) {
      case NONE:
          state = PROBABLY_LEFT;
          break;
      case LEFT_ONLY:
          state = ENGAGING_RIGHT;
          break;
      case RIGHT_ONLY:
          break;
      case BOTH:
          state = RUNNING_ON_THE_LINE;
          break;    
  }
}

inline void probablyLeft() {
  CDC.printf("Probably on the left. Sharp turn...\n");
  sharpRight();
  switch (status) {
      case NONE:
          break;
      case LEFT_ONLY:
          state = ENGAGING_RIGHT;
          break;
      case RIGHT_ONLY:
          state = ENGAGING_LEFT;
          break;
      case BOTH:
          state = RUNNING_ON_THE_LINE;
          break;    
  }
}

inline void probablyRight() {
  CDC.printf("Probably on the right. Sharp turn...\n");
  sharpLeft();
  switch (status) {
      case NONE:
          break;
      case LEFT_ONLY:
          state = ENGAGING_RIGHT;
          break;
      case RIGHT_ONLY:
          state = ENGAGING_LEFT;
          break;
      case BOTH:
          state = RUNNING_ON_THE_LINE;
          break;    
  }
}

inline void whereAmI() {
  CDC.printf("Where the fuck am I?\n");
  stop();
  switch (status) {
      case BOTH:
          state = RUNNING_ON_THE_LINE;
          break;
      case LEFT_ONLY:
          state = ENGAGING_RIGHT;
          break;
      case RIGHT_ONLY:
          state = ENGAGING_LEFT;
          break; 
  }
}

    
inline void readSensors() {  
    int i = 0;
    
    rightSensor =  analogRead(sensor2);
    leftSensor =  analogRead(sensor4);
    status = getStatus(leftSensor, rightSensor);
}

void loop() {
    readSensors();
    sensorsDebug(); 
    stateMachine();
    delay(50);
}

inline void stateMachine() {
    switch (state) {
        case WHERE_AM_I:
            whereAmI();
            break;
        case ENGAGING_LEFT:
            engagingFromLeft();
            break;
        case ENGAGING_RIGHT:
            engagingFromRight();
            break;
        case PROBABLY_LEFT:
            probablyLeft();
            break;
        case PROBABLY_RIGHT:
            probablyRight();
            break;
        case RUNNING_ON_THE_LINE:
            runningOnTheLine();
            break;
    }
}





