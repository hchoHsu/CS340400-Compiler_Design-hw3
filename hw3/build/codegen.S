.global codegen
codegen:
  addi sp, sp, -400
  sd   ra, 392(sp)
  sd   s0, 384(sp)
  addi s0, sp, 400
  li   t0, 65280
  addi sp, sp, -8
  sd   t0, 0(sp)
  ld   t0, 0(sp)
  sd   t0, -24(s0)
  addi sp, sp, 8
  li   t0, 259
  addi sp, sp, -8
  sd   t0, 0(sp)
  ld   t0, 0(sp)
  sd   t0, -32(s0)
  addi sp, sp, 8
  addi sp, sp, -8
  ld   t0, -24(s0)
  sd   t0, 0(sp)
  addi sp, sp, -8
  ld   t0, -32(s0)
  sd   t0, 0(sp)

  ld   t1, 0(sp)
  addi sp, sp, 8
  ld   t0, 0(sp)
  addi sp, sp, 8
  kadd8 t0, t0, t1
  addi sp, sp, -8
  sd   t0, 0(sp)
  ld   t0, 0(sp)
  sd   t0, -40(s0)
  addi sp, sp, 8
  li   t0, 26
  addi sp, sp, -8
  sd   t0, 0(sp)
  li   t0, 1
  addi sp, sp, -8
  sd   t0, 0(sp)
  ld a1, 0(sp)
  addi sp, sp, 8
  ld a0, 0(sp)
  addi sp, sp, 8
  addi sp, sp, -8
  sd ra, 0(sp)
  jal ra, digitalWrite
  ld ra, 0(sp)
  addi sp, sp, 8
  addi sp, sp, -8
  ld   t0, -40(s0)
  sd   t0, 0(sp)
  li   t0, 1000
  addi sp, sp, -8
  sd   t0, 0(sp)
  ld   t1, 0(sp)
  addi sp, sp, 8
  ld   t0, 0(sp)
  mul  t0, t0, t1
  sd   t0, 0(sp)
  ld a0, 0(sp)
  addi sp, sp, 8
  addi sp, sp, -8
  sd ra, 0(sp)
  jal ra, delay
  ld ra, 0(sp)
  addi sp, sp, 8
  li   t0, 26
  addi sp, sp, -8
  sd   t0, 0(sp)
  li   t0, 0
  addi sp, sp, -8
  sd   t0, 0(sp)
  ld a1, 0(sp)
  addi sp, sp, 8
  ld a0, 0(sp)
  addi sp, sp, 8
  addi sp, sp, -8
  sd ra, 0(sp)
  jal ra, digitalWrite
  ld ra, 0(sp)
  addi sp, sp, 8
  addi sp, sp, -8
  ld   t0, -40(s0)
  sd   t0, 0(sp)
  li   t0, 1000
  addi sp, sp, -8
  sd   t0, 0(sp)
  ld   t1, 0(sp)
  addi sp, sp, 8
  ld   t0, 0(sp)
  mul  t0, t0, t1
  sd   t0, 0(sp)
  ld a0, 0(sp)
  addi sp, sp, 8
  addi sp, sp, -8
  sd ra, 0(sp)
  jal ra, delay
  ld ra, 0(sp)
  addi sp, sp, 8
.codegen_funcExit:
  ld   ra, 392(sp)
  ld   s0, 384(sp)
  addi sp, sp, 400
  ret
