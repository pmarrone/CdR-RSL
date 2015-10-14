/*-----------------------------------------------------
Author:  --<>
Date: 2015-10-08
Description:

-----------------------------------------------------*/

u16 ANALOG_MAX = 1023;
int leftSpeed = 11;
int leftDirection = 9;
int rightSpeed = 12;
int rightDirection = 10;
int sensor4 = 13;
int sensor2 = 14;
u8 speed = 900;

void goForward() {
   digitalWrite(leftDirection, HIGH);
   digitalWrite(rightDirection, HIGH);
   digitalWrite(leftSpeed, LOW);
   digitalWrite(rightSpeed, LOW);
}

void goLeft() {
   digitalWrite(leftDirection, LOW);
   digitalWrite(rightDirection, HIGH);
   digitalWrite(leftSpeed, HIGH);
   digitalWrite(rightSpeed, LOW);
}

void goRight() {
   digitalWrite(leftDirection, HIGH);
   digitalWrite(rightDirection, LOW);
   digitalWrite(leftSpeed, LOW);
   digitalWrite(rightSpeed, HIGH);
}

void stop() {
   digitalWrite(leftDirection, LOW);
   digitalWrite(rightDirection, LOW);
   digitalWrite(leftSpeed, LOW);
   digitalWrite(rightSpeed, LOW);
}

void goBack() {
   digitalWrite(leftDirection, LOW);
   digitalWrite(rightDirection, LOW);
   digitalWrite(leftSpeed, HIGH);
   digitalWrite(rightSpeed, HIGH);
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
    stop();
    
}

void moveRobot(int onTheLineness, int errorAmount) {
    if (onTheLineness > 80) {
        if (abs(errorAmount)  < 200) {
            //CDC.printf("Forward!\n");
            goForward();
        } else {
            if (errorAmount > 0) {
                //CDC.printf("Right!\n");
                goRight();
            } else {
                //CDC.printf("Left!\n");
                goLeft();
            }
        }
      
    } else {
        goBack();
    }
}

void readSensors() {
    
    int i = 0;
    u16 rightSensor =  analogRead(sensor2);
    u16 leftSensor =  analogRead(sensor4);

    int errorAmount = rightSensor - leftSensor;
    int onTheLineness = rightSensor + leftSensor;
        
    //angle += 0.01;
    //if (angle > 3.14159) {
    //    angle = 0;
    //}
    
    //CDC.printf("ErrorAmount: %d, OnTheLineness: %d \n", errorAmount, onTheLineness);
    if (errorAmount > 0) {
        //CDC.printf("Go right\n");    
    } else {
        //CDC.printf("Go left\n");
    }
    //CDC.printf("Angle: %f\n", angle);
    //CDC.printf("Left: %d, Right: %d Clock: %u, angle: %f\n", leftSensor, rightSensor, time, angle);
    //CDC.printf("Sin: %f\n", sinf(angle));

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

    moveRobot(onTheLineness, errorAmount);
    
}

void loop() {
    readSensors();
}





