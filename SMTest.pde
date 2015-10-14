/*-----------------------------------------------------
Author:  --<>
Date: 2015-10-08
Description:

-----------------------------------------------------*/
#define RIGHT_ONLY 1
#define LEFT_ONLY 2
#define BOTH 3
#define NONE 4
s16 ANALOG_MAX = 1023;
int leftSpeed = 11;
int leftDirection = 9;
int rightSpeed = 12;
int rightDirection = 10;
int sensor4 = 13;
int sensor2 = 14;
s16 speed = 1000;
s16 mediumSpeed = 800;

double P = 1;
double I = 0.01; 
double D = 1;
u8 status;
u16 rightSensor; 
u16 leftSensor; 

u16 onLineThreshold = 50;

void (*state)();

void whereAmI();
void probablyLeft();
void probablyRight();
void engagingFromLeft();
void engagingFromRight();
void runningOnTheLine();

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

char* getStatusName(u8 status) {
    switch(status) {
        case BOTH:
            return "Both ";
        case LEFT_ONLY:
            return "Left ";
        case RIGHT_ONLY:
            return "Right";
        default:
            return "None ";
    }
}


BOOL isOnLine(u16 reading) {
    return reading > onLineThreshold;
}

void leftWheel(s16 wheelSpeed) {
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

void rightWheel(s16 wheelSpeed) {
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

void wheels(s16 leftWheelSpeed, s16 rightWheelSpeed) {
    //CDC.printf("Wheels called: left: %d, right: %d", leftWheelSpeed, rightWheelSpeed);
    leftWheel(leftWheelSpeed);
    rightWheel(rightWheelSpeed);
}

void turnLeft() {
    wheels(mediumSpeed, 0);
}

void sharpLeft() {
    wheels(mediumSpeed, -0);
}

void turnRight() {
    wheels(mediumSpeed, speed);
}

void sharpRight() {
    wheels(-mediumSpeed, speed);
}

void stop() {
    wheels(0, 0);
}

void fullForward() {
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
    state = &whereAmI;
}

double action;
int errorAmount;
int onTheLineness;
s16 lastError = 0;
s32 errorIntegrator = 0;
s16 errorDiferential;
void control() {
    errorAmount = rightSensor - leftSensor;
    onTheLineness = rightSensor + leftSensor;
    errorIntegrator += errorAmount;
    errorDiferential = errorAmount - lastError;
    lastError = errorAmount;
    action = 1.0 * errorAmount * P + errorIntegrator * I + errorDiferential * D;
}

void controlDebug() {
    CDC.printf("Action: %f, ", action);
    CDC.printf("P: %d, I: %d, ", errorAmount, errorIntegrator);
    CDC.printf("D: %d, LastError: %d", errorDiferential, lastError);
    CDC.printf(", ErrorAmount: %d, OnTheLineness: %d ", errorAmount, onTheLineness);
}

void sensorsDebug() {
    int i;
    //CDC.printf("Status: %s\n", getStatusName(getStatus(leftSensor, rightSensor)));
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

void runningOnTheLine() {
  //CDC.printf("We are doing great!");
  fullForward();
  switch (status) {
      case NONE:
          state = &whereAmI;
          break;
      case LEFT_ONLY:
          state = &engagingFromRight;
          break;
      case RIGHT_ONLY:
          state = &engagingFromLeft;
          break;
      case BOTH:
          //We are still doing great :)
          break;
  }
}

void engagingFromRight() {
  //CDC.printf("Engaging from the right. Turning right slightly...\n");
  turnRight();
  switch (status) {
      case NONE:
          state = &probablyRight;
          break;
      case LEFT_ONLY:
          break;
      case RIGHT_ONLY:
          state = &engagingFromLeft;
          break;
      case BOTH:
          state = &runningOnTheLine;
          break;
      
  }
}

void engagingFromLeft() {
  //CDC.printf("Engaging from the left. Turning left slightly...\n");
  turnLeft();
  switch (status) {
      case NONE:
          state = &probablyLeft;
          break;
      case LEFT_ONLY:
          state = &engagingFromRight;
          break;
      case RIGHT_ONLY:
          break;
      case BOTH:
          state = &runningOnTheLine;
          break;    
  }
}

void probablyLeft() {
  //CDC.printf("Probably on the left. Sharp turn...\n");
  sharpLeft();
  switch (status) {
      case NONE:
          break;
      case LEFT_ONLY:
          state = &engagingFromRight;
          break;
      case RIGHT_ONLY:
          state = &engagingFromLeft;
          break;
      case BOTH:
          state = &runningOnTheLine;
          break;    
  }
}

void probablyRight() {
  //CDC.printf("Probably on the right. Sharp turn...\n");
  sharpRight();
  switch (status) {
      case NONE:
          break;
      case LEFT_ONLY:
          state = &engagingFromRight;
          break;
      case RIGHT_ONLY:
          state = &engagingFromLeft;
          break;
      case BOTH:
          state = &runningOnTheLine;
          break;    
  }
}

void whereAmI() {
  //CDC.printf("Where the fuck am I?\n");
  stop();
  switch (status) {
      case BOTH:
          state = &runningOnTheLine;
          break;
      case LEFT_ONLY:
          state = &engagingFromRight;
          break;
      case RIGHT_ONLY:
          state = &engagingFromLeft;
          break; 
  }
}

    
void readSensors() {  
    int i = 0;
    
    rightSensor =  analogRead(sensor2);
    leftSensor =  analogRead(sensor4);
    status = getStatus(leftSensor, rightSensor);
}

void loop() {
    readSensors();
    sensorsDebug();
    (*state)();
    //fullForward();
    delay(40);
}





