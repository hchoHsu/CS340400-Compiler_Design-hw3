.global codegen
codegen:
  // BEGIN PROLOGUE: codegen is the callee here, so we save callee-saved registers
  addi sp, sp, -104
  sd sp, 96(sp)
  sd s0, 88(sp)
  sd s1, 80(sp)
  sd s2, 72(sp)
  sd s3, 64(sp)
  sd s4, 56(sp)
  sd s5, 48(sp)
  sd s6, 40(sp)
  sd s7, 32(sp)
  sd s8, 24(sp)
  sd s9, 16(sp)
  sd s10, 8(sp)
  sd s11, 0(sp)
  addi s0, sp, 104 // set new frame
  // END PROLOGUE

  addi sp, sp, -8
  sd ra, 0(sp)
  li a0, 27
  li a1, 1
  jal ra, digitalWrite
  ld ra, 0(sp)
  addi sp, sp, 8

  addi sp, sp, -8
  sd ra, 0(sp)
  li a0, 1000
  jal ra, delay
  ld ra, 0(sp)
  addi sp, sp, 8

  addi sp, sp, -8
  sd ra, 0(sp)
  li a0, 27
  li a1, 0
  jal ra, digitalWrite
  ld ra, 0(sp)
  addi sp, sp, 8

  addi sp, sp, -8
  sd ra, 0(sp)
  li a0, 1000
  jal ra, delay
  ld ra, 0(sp)
  addi sp, sp, 8
  
  // BEGIN EPILOGUE: restore callee-saved registers
  // note that here we assume that the stack is properly maintained, which means
  // $sp should point to the same address as when the function prologue exits
  ld sp, 96(sp)
  ld s0, 88(sp)
  ld s1, 80(sp)
  ld s2, 72(sp)
  ld s3, 64(sp)
  ld s4, 56(sp)
  ld s5, 48(sp)
  ld s6, 40(sp)
  ld s7, 32(sp)
  ld s8, 24(sp)
  ld s9, 16(sp)
  ld s10, 8(sp)
  ld s11, 0(sp)
  addi sp, sp, 104
  // END EPILOGUE

  jalr zero, 0(ra) // return
