void codegen();
void codegen()
{
  char4 a = 65280; // a = 00000000_00000000_11111111_00000000
  char4 b = 259;   // b = 00000000_00000000_00000001_00000011
  int c = a + b;   // c = 3  
  digitalWrite(26, HIGH);
  delay(c * 1000); // delay 3 seconds
  digitalWrite(26, LOW);
  delay(c * 1000); // delay 3 seconds
}
