.global codegen
codegen:
  // BEGIN PROLOGUE: codegen is the callee here, so we save callee-saved registers
  addi sp, sp, -52
  sw sp, 48(sp)
  sw s0, 44(sp)
  sw s1, 40(sp)
  sw s2, 36(sp)
  sw s3, 32(sp)
  sw s4, 28(sp)
  sw s5, 24(sp)
  sw s6, 20(sp)
  sw s7, 16(sp)
  sw s8, 12(sp)
  sw s9, 8(sp)
  sw s10, 4(sp)
  sw s11, 0(sp)
  addi s0, sp, 52 // set new frame
  // END PROLOGUE

  addi sp, sp, -4
  sw ra, 0(sp)
  li a0, 27
  li a1, 1
  jal ra, digitalWrite
  lw ra, 0(sp)
  addi sp, sp, 4

  addi sp, sp, -4
  sw ra, 0(sp)
  li a0, 1000
  jal ra, delay
  lw ra, 0(sp)
  addi sp, sp, 4

  addi sp, sp, -4
  sw ra, 0(sp)
  li a0, 27
  li a1, 0
  jal ra, digitalWrite
  lw ra, 0(sp)
  addi sp, sp, 4

  addi sp, sp, -4
  sw ra, 0(sp)
  li a0, 1000
  jal ra, delay
  lw ra, 0(sp)
  addi sp, sp, 4
  
  // BEGIN EPILOGUE: restore callee-saved registers
  // note that here we assume that the stack is properly maintained, which means
  // $sp should point to the same address as when the function prologue exits
  lw sp, 48(sp)
  lw s0, 44(sp)
  lw s1, 40(sp)
  lw s2, 36(sp)
  lw s3, 32(sp)
  lw s4, 28(sp)
  lw s5, 24(sp)
  lw s6, 20(sp)
  lw s7, 16(sp)
  lw s8, 12(sp)
  lw s9, 8(sp)
  lw s10, 4(sp)
  lw s11, 0(sp)
  addi sp, sp, 52
  // END EPILOGUE

  jalr zero, 0(ra) // return
