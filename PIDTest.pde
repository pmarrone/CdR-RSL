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
u16 speed = 704;
double P = 1;
double I = 0.01;
double D = 1;


void leftWheel(s16 wheelSpeed) {
    if (wheelSpeed > ANALOG_MAX ) {
       wheelSpeed = ANALOG_MAX;     
    } else if (wheelSpeed < -ANALOG_MAX) {
       wheelSpeed = -ANALOG_MAX; 
    }
    
    if (wheelSpeed >= 0) {
        digitalWrite(leftDirection, HIGH);
        analogWrite(leftSpeed, wheelSpeed);
    } else {
        digitalWrite(leftDirection, LOW);
        analogWrite(leftSpeed, ANALOG_MAX + wheelSpeed);
    }
}

void rightWheel(s16 wheelSpeed) {
    if (wheelSpeed > ANALOG_MAX ) {
       wheelSpeed = ANALOG_MAX;     
    } else if (wheelSpeed < -ANALOG_MAX) {
       wheelSpeed = -ANALOG_MAX; 
    }
    
    if (wheelSpeed >= 0) {
        digitalWrite(rightDirection , HIGH);
        analogWrite(rightSpeed, wheelSpeed);
    } else {
        digitalWrite(rightDirection, LOW);
        analogWrite(rightSpeed, ANALOG_MAX + wheelSpeed);
    }
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
}

s16 lastError = 0;
s32 errorIntegrator = 0;
    
void readSensors() {
    
    int i = 0;
    u16 rightSensor; 
    u16 leftSensor; 
    s16 errorDiferential;
    int errorAmount;
    int onTheLineness;
    double action;
    
    rightSensor =  analogRead(sensor2);
    leftSensor =  analogRead(sensor4);
    
    errorAmount = rightSensor - leftSensor;
    onTheLineness = rightSensor + leftSensor;
    
    errorIntegrator += errorAmount;
    errorDiferential = errorAmount - lastError;
    lastError = errorAmount;
    action = 1.0 * errorAmount * P + errorIntegrator * I + errorDiferential * D;
    
    //angle += 0.01;
    //if (angle > 3.14159) {
    //    angle = 0;
    //}
    
    CDC.printf("Action: %f, ", action);
    CDC.printf("P: %d, I: %d, ", errorAmount, errorIntegrator);
    CDC.printf("D: %d, LastError: %d", errorDiferential, lastError);
    CDC.printf(", ErrorAmount: %d, OnTheLineness: %d ", errorAmount, onTheLineness);
    
    if (errorAmount > 0) {
        //CDC.printf("Go right\n");    
    } else {
        //CDC.printf("Go left\n");
    }

    CDC.printf(",Left: %d, Right: %d", leftSensor, rightSensor);
    
    CDC.printf("\n");
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

    delay(400);
    //delay(200);
    /*
    speed = speed + 1;
    if(speed > ANALOG_MAX) {
        speed = 0;
    }
    CDC.printf("Speed: %d\n", speed);
    
    delay(10);
    goSpeed(speed);
    */
}

void loop() {
    readSensors();
}





