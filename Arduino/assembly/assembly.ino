extern "C" void codegen() asm ("codegen");

void setup() {
  // put your setup code here, to run once:
  pinMode(LED1, OUTPUT); // LED1 = 26
  pinMode(LED2, OUTPUT); // LED2 = 27
  pinMode(LED3, OUTPUT); // LED3 = 28
  pinMode(LED4, OUTPUT); // LED4 = 29
}

void loop() {
  // put your main code here, to run repeatedly:
  codegen();
}
